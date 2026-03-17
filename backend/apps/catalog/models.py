from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import Q
from django.utils.text import slugify

from .choices import (
    ItemKind,
    LetterColor,
    Origin,
    PlyRating,
    ProductCategory,
    RimDiameter,
    RimHoles,
    RimMaterial,
    RimWidthIn,
    TireType,
    TreadType,
)


class ActiveCatalogQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)


class Brand(models.Model):
    name = models.CharField(max_length=120, unique=True, db_index=True)
    logo_image = models.ForeignKey(
        "images.ImageAsset",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="brand_logos",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class CatalogItem(models.Model):
    sku = models.CharField(max_length=64, unique=True)
    code = models.CharField(max_length=64, null=True, blank=True)
    item_kind = models.CharField(max_length=16, choices=ItemKind.choices)
    product_category = models.CharField(max_length=32, choices=ProductCategory.choices)
    brand = models.ForeignKey(
        Brand,
        on_delete=models.PROTECT,
        related_name="catalog_items",
        null=True,
        blank=True,
    )
    model = models.CharField(max_length=120, null=True, blank=True)
    origin = models.CharField(
        max_length=32,
        choices=Origin.choices,
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    objects = ActiveCatalogQuerySet.as_manager()

    SERVICE_CATEGORIES = {
        ProductCategory.RIM_REPAIR,
        ProductCategory.RIM_BALANCE,
        ProductCategory.PAINTING,
        ProductCategory.TIRE_MOUNTING,
        ProductCategory.TIRE_PATCHING,
        ProductCategory.SERVICE_GENERAL,
    }
    MERCHANDISE_CATEGORIES = {
        ProductCategory.TIRE,
        ProductCategory.RIM,
        ProductCategory.ACCESSORY,
    }

    class Meta:
        ordering = ["product_category", "sku", "brand__name", "model"]
        constraints = [
            models.UniqueConstraint(
                fields=["code", "brand", "model", "product_category"],
                condition=Q(product_category__in=[ProductCategory.TIRE, ProductCategory.RIM]),
                name="catalog_unique_code_brand_model_category_for_goods",
            ),
        ]
        indexes = [
            models.Index(fields=["item_kind", "product_category", "is_active"]),
            models.Index(fields=["code"]),
        ]

    def clean(self):
        super().clean()
        if self.model is not None:
            self.model = self.model.strip() or None
        if self.code is not None:
            self.code = self.code.strip() or None
        if self.sku is not None:
            self.sku = self.sku.strip()

        is_service = self.item_kind == ItemKind.SERVICE
        is_merchandise = self.item_kind == ItemKind.MERCHANDISE

        if is_service and self.product_category not in self.SERVICE_CATEGORIES:
            raise ValidationError(
                {"product_category": "Service items must use a service category."}
            )

        if is_merchandise and self.product_category not in self.MERCHANDISE_CATEGORIES:
            raise ValidationError(
                {"product_category": "Merchandise items must use a merchandise category."}
            )

        if is_service and self.origin:
            raise ValidationError({"origin": "Service items should not define origin."})

        if self.product_category == ProductCategory.TIRE and not self.origin:
            raise ValidationError({"origin": "Tire catalog items require origin."})

        if self.product_category in {ProductCategory.TIRE, ProductCategory.RIM} and not self.brand:
            raise ValidationError({"brand": "Brand is required for tire and rim catalog items."})

        if self.product_category == ProductCategory.TIRE and not self.code:
            raise ValidationError({"code": "Tire catalog items require a size code."})

        if self.product_category == ProductCategory.RIM and not self.code:
            raise ValidationError({"code": "Rim catalog items require an internal code."})

        if is_service and self.code:
            raise ValidationError({"code": "Service items should not define a tire size code."})

    def __str__(self) -> str:
        brand_name = self.brand.name if self.brand else "No Brand"
        return f"{self.sku} - {brand_name}"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class TireSpec(models.Model):
    catalog_item = models.OneToOneField(
        CatalogItem,
        on_delete=models.CASCADE,
        related_name="tire_spec",
    )
    tire_type = models.CharField(max_length=16, choices=TireType.choices)
    width = models.PositiveIntegerField()
    aspect_ratio = models.PositiveIntegerField(null=True, blank=True)
    rim_diameter = models.CharField(max_length=3, choices=RimDiameter.choices)
    ply_rating = models.CharField(max_length=4, choices=PlyRating.choices)
    tread_type = models.CharField(max_length=16, choices=TreadType.choices)
    letter_color = models.CharField(
        max_length=16,
        choices=LetterColor.choices,
        default=LetterColor.BLACK,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    ASPECT_RATIO_REQUIRED_TYPES = {
        TireType.RADIAL,
        TireType.MILLIMETRIC,
    }

    class Meta:
        ordering = ["catalog_item__sku"]

    def clean(self):
        super().clean()
        if self.catalog_item.product_category != ProductCategory.TIRE:
            raise ValidationError({"catalog_item": "TireSpec can only be attached to TIRE catalog items."})

        if (
            self.tire_type in self.ASPECT_RATIO_REQUIRED_TYPES
            and self.aspect_ratio is None
        ):
            raise ValidationError(
                {"aspect_ratio": "Aspect ratio is required for the selected tire type."}
            )

        if (
            self.tire_type == TireType.CONVENTIONAL
            and self.aspect_ratio is not None
        ):
            raise ValidationError(
                {"aspect_ratio": "Conventional tire types should not define aspect ratio."}
            )

    @classmethod
    def build_code_from_spec(cls, width, rim_diameter, aspect_ratio=None):
        if aspect_ratio:
            return f"{width}/{aspect_ratio}{rim_diameter}"
        return f"{width}{rim_diameter}"

    def suggested_code(self):
        return self.build_code_from_spec(
            width=self.width,
            aspect_ratio=self.aspect_ratio,
            rim_diameter=self.rim_diameter,
        )

    def __str__(self) -> str:
        return self.suggested_code()

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


class RimSpec(models.Model):
    catalog_item = models.OneToOneField(
        CatalogItem,
        on_delete=models.CASCADE,
        related_name="rim_spec",
    )
    rim_diameter = models.CharField(max_length=3, choices=RimDiameter.choices)
    holes = models.PositiveSmallIntegerField(choices=RimHoles.choices)
    width_in = models.PositiveSmallIntegerField(choices=RimWidthIn.choices)
    material = models.CharField(max_length=16, choices=RimMaterial.choices)
    is_set = models.BooleanField(default=False)
    photo_image = models.ForeignKey(
        "images.ImageAsset",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="rim_photos",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["catalog_item__sku"]

    def clean(self):
        super().clean()
        if self.catalog_item.product_category != ProductCategory.RIM:
            raise ValidationError({"catalog_item": "RimSpec can only be attached to RIM catalog items."})

    def __str__(self) -> str:
        kind = "SET" if self.is_set else "SINGLE"
        return f"{self.rim_diameter} {self.holes}H {self.width_in}IN {kind}"

    def save(self, *args, **kwargs):
        self.full_clean()
        return super().save(*args, **kwargs)


def build_tire_sku(*, brand_name, width, rim_diameter, model=None, aspect_ratio=None):
    parts = [
        "TIRE",
        slugify(brand_name).upper() or "BRAND",
        str(width),
    ]
    if aspect_ratio is not None:
        parts.append(str(aspect_ratio))
    parts.append(rim_diameter.upper())
    if model:
        parts.append(slugify(model).upper())
    return "-".join(part for part in parts if part)[:64]


def build_rim_sku(*, brand_name, internal_code):
    return "-".join(
        [
            "RIM",
            slugify(brand_name).upper() or "BRAND",
            slugify(internal_code).upper() or "CODE",
        ]
    )[:64]
