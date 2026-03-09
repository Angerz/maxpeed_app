from decimal import Decimal, ROUND_HALF_UP

from django.db.models import Q
from django.db import transaction
from django.utils import timezone

from apps.catalog.choices import ItemKind, Origin, ProductCategory
from apps.catalog.models import Brand, CatalogItem, RimSpec, TireSpec, build_rim_sku, build_tire_sku
from apps.inventory.models import InventoryCondition, InventoryItem, MovementType, Owner, PriceType
from apps.inventory.services.core import apply_inventory_movement, set_current_price
from apps.sales.models import Sale, SaleLine, SaleLineType, SaleStatus


class SaleConflictError(Exception):
    pass


class SaleForbiddenError(Exception):
    pass


class TradeInSpecConflictError(Exception):
    pass


def _build_inventory_snapshot(inventory_item):
    catalog_item = inventory_item.catalog_item
    brand_name = catalog_item.brand.name if catalog_item.brand else None
    owner_name = inventory_item.owner.name if inventory_item.owner else None

    details = []
    if catalog_item.product_category == ProductCategory.TIRE:
        tire_spec = getattr(catalog_item, "tire_spec", None)
        if catalog_item.origin:
            details.append(catalog_item.origin)
        if tire_spec and tire_spec.ply_rating:
            details.append(tire_spec.ply_rating)
        if tire_spec and tire_spec.tread_type:
            details.append(tire_spec.tread_type)
    elif catalog_item.product_category == ProductCategory.RIM:
        rim_spec = getattr(catalog_item, "rim_spec", None)
        if rim_spec:
            set_label = "SET" if rim_spec.is_set else "SINGLE"
            details.extend(
                [
                    rim_spec.material,
                    f"{rim_spec.holes}H",
                    f"{rim_spec.width_in}IN",
                    set_label,
                ]
            )
    return {
        "code": catalog_item.code,
        "brand": brand_name,
        "owner_name": owner_name,
        "details": " | ".join(details) if details else None,
    }


def _normalized_model(value):
    if value is None:
        return None
    cleaned = value.strip()
    return cleaned or None


def _build_unique_tire_sku(*, brand_name, width, rim_diameter, model=None, aspect_ratio=None):
    base_sku = build_tire_sku(
        brand_name=brand_name,
        width=width,
        rim_diameter=rim_diameter,
        model=model,
        aspect_ratio=aspect_ratio,
    )
    candidate = base_sku
    suffix = 1
    while CatalogItem.objects.filter(sku=candidate).exists():
        suffix += 1
        candidate = f"{base_sku[:57]}-{suffix}"[:64]
    return candidate


def _build_unique_rim_sku(*, brand_name, internal_code):
    base_sku = build_rim_sku(brand_name=brand_name, internal_code=internal_code)
    candidate = base_sku
    suffix = 1
    while CatalogItem.objects.filter(sku=candidate).exists():
        suffix += 1
        candidate = f"{base_sku[:57]}-{suffix}"[:64]
    return candidate


def ingest_tradein_tire(*, sale_line, line_payload, user, occurred_at):
    tire_payload = line_payload["tire"]
    if tire_payload["owner"].name.upper() not in {"MAXPEED", "RUEL"}:
        raise SaleForbiddenError("Trade-in USED inventory owner must be Maxpeed or Ruel.")
    suggested_sale_price = tire_payload.get("suggested_sale_price")
    assessed_value = line_payload["assessed_value"]
    if suggested_sale_price is None:
        suggested_sale_price = (assessed_value * Decimal("1.30")).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )

    normalized_model = _normalized_model(tire_payload.get("model"))
    catalog_query = CatalogItem.objects.select_for_update().filter(
        item_kind=ItemKind.MERCHANDISE,
        product_category=ProductCategory.TIRE,
        brand=tire_payload["brand"],
        origin=tire_payload["origin"],
    )
    if normalized_model is None:
        catalog_query = catalog_query.filter(Q(model__isnull=True) | Q(model=""))
    else:
        catalog_query = catalog_query.filter(model=normalized_model)
    catalog_query = catalog_query.filter(
        tire_spec__tire_type=tire_payload["tire_type"],
        tire_spec__width=tire_payload["width"],
        tire_spec__aspect_ratio=tire_payload.get("aspect_ratio"),
        tire_spec__rim_diameter=tire_payload["rim_diameter"],
        tire_spec__ply_rating=tire_payload["ply_rating"],
        tire_spec__tread_type=tire_payload["tread_type"],
        tire_spec__letter_color=tire_payload["letter_color"],
    )
    catalog_item = catalog_query.first()
    if catalog_item is None:
        catalog_item = CatalogItem.objects.create(
            sku=_build_unique_tire_sku(
                brand_name=tire_payload["brand"].name,
                width=tire_payload["width"],
                rim_diameter=tire_payload["rim_diameter"],
                model=normalized_model,
                aspect_ratio=tire_payload.get("aspect_ratio"),
            ),
            code=TireSpec.build_code_from_spec(
                width=tire_payload["width"],
                aspect_ratio=tire_payload.get("aspect_ratio"),
                rim_diameter=tire_payload["rim_diameter"],
            ),
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.TIRE,
            brand=tire_payload["brand"],
            model=normalized_model,
            origin=tire_payload["origin"],
            is_active=True,
        )
        TireSpec.objects.create(
            catalog_item=catalog_item,
            tire_type=tire_payload["tire_type"],
            width=tire_payload["width"],
            aspect_ratio=tire_payload.get("aspect_ratio"),
            rim_diameter=tire_payload["rim_diameter"],
            ply_rating=tire_payload["ply_rating"],
            tread_type=tire_payload["tread_type"],
            letter_color=tire_payload["letter_color"],
        )

    inventory_item, _ = InventoryItem.objects.select_for_update().get_or_create(
        catalog_item=catalog_item,
        condition=InventoryCondition.USED,
        owner=tire_payload["owner"],
        defaults={"stock": 0, "is_active": True},
    )
    if not inventory_item.is_active:
        inventory_item.is_active = True
        inventory_item.deactivated_at = None
        inventory_item.save(update_fields=["is_active", "deactivated_at", "updated_at"])

    movement = apply_inventory_movement(
        inventory_item=inventory_item,
        movement_type=MovementType.TRADEIN_IN,
        quantity=line_payload["quantity"],
        unit_cost=assessed_value,
        occurred_at=occurred_at,
        reference_type="sale_line_tradein",
        reference_id=str(sale_line.id),
        notes=line_payload.get("notes") or line_payload.get("description"),
        created_by=user,
    )
    set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.PURCHASE,
        amount=assessed_value,
        user=user,
        valid_from=occurred_at,
    )
    set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.SUGGESTED_SALE,
        amount=suggested_sale_price,
        user=user,
        valid_from=occurred_at,
    )
    return {
        "sale_line_id": sale_line.id,
        "created_inventory_item_id": inventory_item.id,
        "catalog_item_id": catalog_item.id,
        "movement_id": movement.id,
    }


def ingest_tradein_rim(*, sale_line, line_payload, user, occurred_at):
    rim_payload = line_payload["rim"]
    if rim_payload["owner"].name.upper() not in {"MAXPEED", "RUEL"}:
        raise SaleForbiddenError("Trade-in USED inventory owner must be Maxpeed or Ruel.")
    suggested_sale_price = rim_payload.get("suggested_sale_price")
    assessed_value = line_payload["assessed_value"]
    if suggested_sale_price is None:
        suggested_sale_price = (assessed_value * Decimal("1.30")).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )

    internal_code = rim_payload["internal_code"].strip()
    existing_catalog = (
        CatalogItem.objects.select_for_update()
        .filter(
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.RIM,
            brand=rim_payload["brand"],
            code=internal_code,
        )
        .filter(Q(model__isnull=True) | Q(model=""))
        .first()
    )
    if existing_catalog:
        rim_spec = getattr(existing_catalog, "rim_spec", None)
        if rim_spec is None:
            raise TradeInSpecConflictError("Existing rim catalog item has no RimSpec.")
        incoming_signature = (
            rim_payload["rim_diameter"],
            int(rim_payload["holes"]),
            int(rim_payload["width_in"]),
            rim_payload["material"],
            rim_payload["is_set"],
        )
        current_signature = (
            rim_spec.rim_diameter,
            rim_spec.holes,
            rim_spec.width_in,
            rim_spec.material,
            rim_spec.is_set,
        )
        if incoming_signature != current_signature:
            raise TradeInSpecConflictError("internal_code already exists with different rim specs.")
        catalog_item = existing_catalog
    else:
        catalog_item = CatalogItem.objects.create(
            sku=_build_unique_rim_sku(brand_name=rim_payload["brand"].name, internal_code=internal_code),
            code=internal_code,
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.RIM,
            brand=rim_payload["brand"],
            model=None,
            origin=None,
            is_active=True,
        )
        RimSpec.objects.create(
            catalog_item=catalog_item,
            rim_diameter=rim_payload["rim_diameter"],
            holes=rim_payload["holes"],
            width_in=rim_payload["width_in"],
            material=rim_payload["material"],
            is_set=rim_payload["is_set"],
        )

    inventory_item, _ = InventoryItem.objects.select_for_update().get_or_create(
        catalog_item=catalog_item,
        condition=InventoryCondition.USED,
        owner=rim_payload["owner"],
        defaults={"stock": 0, "is_active": True},
    )
    if not inventory_item.is_active:
        inventory_item.is_active = True
        inventory_item.deactivated_at = None
        inventory_item.save(update_fields=["is_active", "deactivated_at", "updated_at"])

    movement = apply_inventory_movement(
        inventory_item=inventory_item,
        movement_type=MovementType.TRADEIN_IN,
        quantity=line_payload["quantity"],
        unit_cost=assessed_value,
        occurred_at=occurred_at,
        reference_type="sale_line_tradein",
        reference_id=str(sale_line.id),
        notes=line_payload.get("notes") or line_payload.get("description"),
        created_by=user,
    )
    set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.PURCHASE,
        amount=assessed_value,
        user=user,
        valid_from=occurred_at,
    )
    set_current_price(
        inventory_item=inventory_item,
        price_type=PriceType.SUGGESTED_SALE,
        amount=suggested_sale_price,
        user=user,
        valid_from=occurred_at,
    )
    return {
        "sale_line_id": sale_line.id,
        "created_inventory_item_id": inventory_item.id,
        "catalog_item_id": catalog_item.id,
        "movement_id": movement.id,
    }


@transaction.atomic
def create_sale(*, payload, user=None):
    sold_at = payload.get("sold_at") or timezone.now()
    header_discount = payload.get("discount_total") or Decimal("0.00")
    notes = payload.get("notes")
    lines = payload["lines"]

    inventory_line_ids = [line["inventory_item_id"] for line in lines if line["line_type"] in SaleLineType.inventory_values()]
    locked_inventory = {
        item.id: item
        for item in InventoryItem.objects.select_for_update()
        .select_related("catalog_item", "owner")
        .filter(id__in=inventory_line_ids)
    }

    if len(locked_inventory) != len(set(inventory_line_ids)):
        raise SaleConflictError("One or more inventory items do not exist.")

    sale = Sale.objects.create(
        sold_at=sold_at,
        status=SaleStatus.CONFIRMED,
        subtotal=Decimal("0.00"),
        discount_total=Decimal("0.00"),
        tradein_credit_total=Decimal("0.00"),
        total=Decimal("0.00"),
        total_due=Decimal("0.00"),
        notes=notes,
        created_by=user,
    )

    subtotal = Decimal("0.00")
    line_discount_total = Decimal("0.00")
    tradein_credit_total = Decimal("0.00")
    stock_updates = []
    tradein_ingress = []

    for line in lines:
        line_type = line["line_type"]
        quantity = line["quantity"]

        if line_type in SaleLineType.inventory_values():
            inventory_item = locked_inventory[line["inventory_item_id"]]
            if not inventory_item.is_active:
                raise SaleConflictError(f"Inventory item {inventory_item.id} is inactive.")

            category = inventory_item.catalog_item.product_category
            if line_type == SaleLineType.INVENTORY_TIRE and category != ProductCategory.TIRE:
                raise SaleConflictError("Inventory line type INVENTORY_TIRE requires a tire inventory item.")
            if line_type == SaleLineType.INVENTORY_RIM and category != ProductCategory.RIM:
                raise SaleConflictError("Inventory line type INVENTORY_RIM requires a rim inventory item.")
            if quantity > inventory_item.stock:
                raise SaleConflictError(f"Insufficient stock for inventory item {inventory_item.id}.")

            unit_price = line["unit_price"]
            discount = line.get("discount") or Decimal("0.00")
            gross = unit_price * quantity
            line_total = gross - discount
            if line_total < 0:
                raise SaleConflictError("Line discount cannot exceed gross amount.")

            snapshot = _build_inventory_snapshot(inventory_item)
            sale_line = SaleLine.objects.create(
                sale=sale,
                line_type=line_type,
                inventory_item=inventory_item,
                quantity=quantity,
                unit_price=unit_price,
                discount=discount,
                line_total=line_total,
                description=line.get("description"),
                code=snapshot["code"],
                brand=snapshot["brand"],
                owner_name=snapshot["owner_name"],
                details=snapshot["details"],
            )
            stock_before = inventory_item.stock
            apply_inventory_movement(
                inventory_item=inventory_item,
                movement_type=MovementType.SALE_OUT,
                quantity=-quantity,
                occurred_at=sold_at,
                reference_type="sale_line",
                reference_id=str(sale_line.id),
                notes=notes,
                created_by=user,
            )
            stock_updates.append(
                {
                    "inventory_item_id": inventory_item.id,
                    "stock_before": stock_before,
                    "stock_after": inventory_item.stock,
                }
            )
            subtotal += gross
            line_discount_total += discount
            continue

        if line_type in SaleLineType.manual_values():
            unit_price = line["unit_price"]
            discount = line.get("discount") or Decimal("0.00")
            gross = unit_price * quantity
            line_total = gross - discount
            if line_total < 0:
                raise SaleConflictError("Line discount cannot exceed gross amount.")

            SaleLine.objects.create(
                sale=sale,
                line_type=line_type,
                quantity=quantity,
                unit_price=unit_price,
                discount=discount,
                line_total=line_total,
                description=line["description"],
            )
            subtotal += gross
            line_discount_total += discount
            continue

        assessed_value = line["assessed_value"]
        line_credit = assessed_value * quantity
        details = []
        if line_type == SaleLineType.TRADEIN_TIRE and line.get("tire_condition_percent") is not None:
            details.append(f"Condition {line['tire_condition_percent']}%")
        if line_type == SaleLineType.TRADEIN_RIM and line.get("rim_requires_repair") is not None:
            details.append("Requires repair" if line["rim_requires_repair"] else "No repair")

        if line_type == SaleLineType.TRADEIN_TIRE:
            line_code = TireSpec.build_code_from_spec(
                width=line["tire"]["width"],
                aspect_ratio=line["tire"].get("aspect_ratio"),
                rim_diameter=line["tire"]["rim_diameter"],
            )
            line_brand = line["tire"]["brand"].name
        else:
            line_code = line["rim"]["internal_code"]
            line_brand = line["rim"]["brand"].name

        sale_line = SaleLine.objects.create(
            sale=sale,
            line_type=line_type,
            quantity=quantity,
            unit_price=Decimal("0.00"),
            discount=Decimal("0.00"),
            line_total=Decimal("0.00"),
            description=line.get("description"),
            code=line_code,
            brand=line_brand,
            owner_name=(line.get("tire") or line.get("rim") or {}).get("owner").name,
            details=" | ".join(details) if details else None,
            assessed_value=assessed_value,
            tire_condition_percent=line.get("tire_condition_percent"),
            rim_requires_repair=line.get("rim_requires_repair"),
            inventory_item=None,
        )
        try:
            if line_type == SaleLineType.TRADEIN_TIRE:
                ingress_payload = ingest_tradein_tire(
                    sale_line=sale_line,
                    line_payload=line,
                    user=user,
                    occurred_at=sold_at,
                )
            else:
                ingress_payload = ingest_tradein_rim(
                    sale_line=sale_line,
                    line_payload=line,
                    user=user,
                    occurred_at=sold_at,
                )
        except TradeInSpecConflictError as exc:
            raise SaleConflictError(str(exc)) from exc
        sale_line.inventory_item_id = ingress_payload["created_inventory_item_id"]
        sale_line.save(update_fields=["inventory_item"])
        tradein_ingress.append(ingress_payload)
        tradein_credit_total += line_credit

    discount_total = line_discount_total + header_discount
    total = subtotal - discount_total
    if total < 0:
        raise SaleConflictError("Total discount exceeds subtotal.")
    total_due = total - tradein_credit_total
    if total_due < 0:
        total_due = Decimal("0.00")

    sale.subtotal = subtotal
    sale.discount_total = discount_total
    sale.tradein_credit_total = tradein_credit_total
    sale.total = total
    sale.total_due = total_due
    sale.status = SaleStatus.CONFIRMED
    sale.save(update_fields=["subtotal", "discount_total", "tradein_credit_total", "total", "total_due", "status"])

    return {
        "sale_id": sale.id,
        "totals": {
            "subtotal": sale.subtotal,
            "discount_total": sale.discount_total,
            "tradein_credit_total": sale.tradein_credit_total,
            "total": sale.total,
            "total_due": sale.total_due,
        },
        "stock_updates": stock_updates,
        "tradein_ingress": tradein_ingress,
        "status": sale.status,
    }
