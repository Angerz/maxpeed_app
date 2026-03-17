import io

from django.core.management import call_command
from django.test import TestCase
from PIL import Image

from apps.catalog.choices import ItemKind, ProductCategory, RimDiameter, RimMaterial, RimWidthIn, RimHoles
from apps.catalog.models import Brand, CatalogItem, RimSpec
from apps.images.models import ImageAsset, ImageKind, ImageVariant


def _png_bytes(color):
    image = Image.new("RGB", (1400, 900), color=color)
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


class BackfillImageThumbsCommandTests(TestCase):
    def test_backfill_creates_missing_thumbs_for_brand_and_rim(self):
        full_brand = ImageAsset.objects.create(
            kind=ImageKind.BRAND_LOGO,
            variant=ImageVariant.FULL,
            mime_type="image/png",
            data=_png_bytes("red"),
            size_bytes=0,
        )
        full_rim = ImageAsset.objects.create(
            kind=ImageKind.RIM_PHOTO,
            variant=ImageVariant.FULL,
            mime_type="image/png",
            data=_png_bytes("blue"),
            size_bytes=0,
        )

        brand = Brand.objects.create(name="BACKFILL-BRAND", logo_image=full_brand)
        catalog_item = CatalogItem.objects.create(
            sku="RIM-BACKFILL-BRAND-RIM-001",
            code="RIM-001",
            item_kind=ItemKind.MERCHANDISE,
            product_category=ProductCategory.RIM,
            brand=brand,
            model=None,
            origin=None,
        )
        rim_spec = RimSpec.objects.create(
            catalog_item=catalog_item,
            rim_diameter=RimDiameter.R15,
            holes=RimHoles.H5,
            width_in=RimWidthIn.W8,
            material=RimMaterial.ALUMINUM,
            is_set=False,
            photo_image=full_rim,
        )

        call_command("backfill_image_thumbs")

        brand.refresh_from_db()
        rim_spec.refresh_from_db()

        self.assertEqual(brand.logo_image_full_id, full_brand.id)
        self.assertIsNotNone(brand.logo_image_thumb_id)
        self.assertEqual(brand.logo_image_thumb.variant, ImageVariant.THUMB)

        self.assertEqual(rim_spec.photo_image_full_id, full_rim.id)
        self.assertIsNotNone(rim_spec.photo_image_thumb_id)
        self.assertEqual(rim_spec.photo_image_thumb.variant, ImageVariant.THUMB)

        thumb_count_before = ImageAsset.objects.filter(variant=ImageVariant.THUMB).count()
        call_command("backfill_image_thumbs")
        thumb_count_after = ImageAsset.objects.filter(variant=ImageVariant.THUMB).count()
        self.assertEqual(thumb_count_before, thumb_count_after)
