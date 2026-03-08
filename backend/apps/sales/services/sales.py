from decimal import Decimal
from uuid import uuid4

from django.db import transaction
from django.utils import timezone

from apps.catalog.choices import ItemKind, Origin, ProductCategory
from apps.catalog.models import Brand, CatalogItem
from apps.inventory.models import InventoryCondition, InventoryItem, MovementType, Owner
from apps.inventory.services.core import apply_inventory_movement
from apps.sales.models import Sale, SaleLine, SaleLineType, SaleStatus


class SaleConflictError(Exception):
    pass


class SaleForbiddenError(Exception):
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


def _get_tradein_inventory_item(*, line_type):
    brand, _ = Brand.objects.get_or_create(name="TRADE-IN")
    if line_type == SaleLineType.TRADEIN_TIRE:
        catalog_item, _ = CatalogItem.objects.get_or_create(
            sku="TRADEIN-TIRE-USED-GENERIC",
            defaults={
                "code": "TRADEIN-TIRE",
                "item_kind": ItemKind.MERCHANDISE,
                "product_category": ProductCategory.TIRE,
                "brand": brand,
                "origin": Origin.OTHER,
                "is_active": True,
            },
        )
    else:
        catalog_item, _ = CatalogItem.objects.get_or_create(
            sku="TRADEIN-RIM-USED-GENERIC",
            defaults={
                "code": "TRADEIN-RIM",
                "item_kind": ItemKind.MERCHANDISE,
                "product_category": ProductCategory.RIM,
                "brand": brand,
                "is_active": True,
            },
        )

    owner = Owner.objects.filter(name__iexact="Maxpeed").first() or Owner.objects.order_by("id").first()

    if owner is None:
        raise SaleConflictError("No active owner available for trade-in inventory.")

    inventory_item, _ = InventoryItem.objects.select_for_update().get_or_create(
        catalog_item=catalog_item,
        condition=InventoryCondition.USED,
        owner=owner,
        defaults={"stock": 0, "is_active": True},
    )
    if not inventory_item.is_active:
        inventory_item.is_active = True
        inventory_item.deactivated_at = None
        inventory_item.save(update_fields=["is_active", "deactivated_at", "updated_at"])
    return inventory_item


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
            if category == ProductCategory.RIM and inventory_item.owner.name.upper() == "ALDO":
                raise SaleForbiddenError("ALDO-owned rim inventory cannot be sold.")
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

        tradein_inventory_item = _get_tradein_inventory_item(line_type=line_type)
        apply_inventory_movement(
            inventory_item=tradein_inventory_item,
            movement_type=MovementType.TRADEIN_IN,
            quantity=quantity,
            unit_cost=assessed_value,
            occurred_at=sold_at,
            reference_type="sale_tradein",
            reference_id=f"{sale.id}-{uuid4().hex[:8]}",
            notes=line.get("description") or notes,
            created_by=user,
        )

        SaleLine.objects.create(
            sale=sale,
            line_type=line_type,
            inventory_item=tradein_inventory_item,
            quantity=quantity,
            unit_price=Decimal("0.00"),
            discount=Decimal("0.00"),
            line_total=Decimal("0.00"),
            description=line.get("description"),
            code=tradein_inventory_item.catalog_item.code,
            brand=tradein_inventory_item.catalog_item.brand.name if tradein_inventory_item.catalog_item.brand else None,
            owner_name=tradein_inventory_item.owner.name if tradein_inventory_item.owner else None,
            details=" | ".join(details) if details else None,
            assessed_value=assessed_value,
            tire_condition_percent=line.get("tire_condition_percent"),
            rim_requires_repair=line.get("rim_requires_repair"),
        )
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
        "status": sale.status,
    }
