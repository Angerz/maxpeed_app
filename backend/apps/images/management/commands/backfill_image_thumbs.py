from django.core.management.base import BaseCommand

from apps.catalog.models import Brand, RimSpec
from apps.images.services import create_thumb_variant_from_full


class Command(BaseCommand):
    help = "Backfill THUMB variants for brand logos and rim photos."

    def handle(self, *args, **options):
        brand_updated = 0
        rim_updated = 0

        for brand in Brand.objects.select_related("logo_image", "logo_image_full", "logo_image_thumb"):
            full = brand.logo_image_full or brand.logo_image
            if full is None:
                continue
            update_fields = []
            if brand.logo_image_full_id is None:
                brand.logo_image_full = full
                update_fields.append("logo_image_full")
            if brand.logo_image_id is None:
                brand.logo_image = full
                update_fields.append("logo_image")
            if brand.logo_image_thumb_id is None:
                brand.logo_image_thumb = create_thumb_variant_from_full(image_asset=full)
                update_fields.append("logo_image_thumb")
            if update_fields:
                brand.save(update_fields=update_fields)
                brand_updated += 1

        for rim_spec in RimSpec.objects.select_related(
            "photo_image",
            "photo_image_full",
            "photo_image_thumb",
        ):
            full = rim_spec.photo_image_full or rim_spec.photo_image
            if full is None:
                continue
            update_fields = []
            if rim_spec.photo_image_full_id is None:
                rim_spec.photo_image_full = full
                update_fields.append("photo_image_full")
            if rim_spec.photo_image_id is None:
                rim_spec.photo_image = full
                update_fields.append("photo_image")
            if rim_spec.photo_image_thumb_id is None:
                rim_spec.photo_image_thumb = create_thumb_variant_from_full(image_asset=full)
                update_fields.append("photo_image_thumb")
            if update_fields:
                rim_spec.save(update_fields=update_fields)
                rim_updated += 1

        self.stdout.write(self.style.SUCCESS(f"Brands updated: {brand_updated}"))
        self.stdout.write(self.style.SUCCESS(f"Rim specs updated: {rim_updated}"))
