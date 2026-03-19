import mimetypes
import re
import unicodedata
from pathlib import Path

from django.core.files.uploadedfile import SimpleUploadedFile
from django.core.management.base import BaseCommand, CommandError

from apps.catalog.models import Brand
from apps.images.models import ImageKind
from apps.images.services import create_image_variants_from_upload


def _normalize_key(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value or "")
    ascii_only = normalized.encode("ascii", "ignore").decode("ascii")
    lowered = ascii_only.lower()
    return re.sub(r"[^a-z0-9]+", "", lowered)


class Command(BaseCommand):
    help = (
        "Importa logos de marcas desde una carpeta (archivos por nombre normalizado) "
        "y asigna full/thumb en catalog_brand."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--dir",
            required=True,
            help="Ruta de la carpeta con logos (png/jpg/jpeg/webp).",
        )
        parser.add_argument(
            "--overwrite",
            action="store_true",
            help="Sobrescribe logos existentes.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Muestra qué haría sin escribir en la BD.",
        )

    def handle(self, *args, **options):
        base_dir = Path(options["dir"]).expanduser().resolve()
        overwrite = bool(options["overwrite"])
        dry_run = bool(options["dry_run"])

        if not base_dir.exists() or not base_dir.is_dir():
            raise CommandError(f"La ruta no existe o no es carpeta: {base_dir}")

        files_by_key = {}
        for entry in sorted(base_dir.iterdir()):
            if not entry.is_file():
                continue
            if entry.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
                continue
            key = _normalize_key(entry.stem)
            if not key:
                continue
            if key in files_by_key:
                self.stdout.write(
                    self.style.WARNING(
                        f"Archivo duplicado para clave '{key}': {entry.name} "
                        f"(se mantiene {files_by_key[key].name})"
                    )
                )
                continue
            files_by_key[key] = entry

        if not files_by_key:
            raise CommandError(f"No se encontraron imágenes válidas en: {base_dir}")

        matched = 0
        created = 0
        skipped = 0
        missing = []

        brands = Brand.objects.all().order_by("name")
        for brand in brands:
            brand_key = _normalize_key(brand.name)
            image_path = files_by_key.get(brand_key)
            if image_path is None:
                missing.append(brand.name)
                continue

            has_logo = bool(brand.logo_image_full_id or brand.logo_image_id)
            if has_logo and not overwrite:
                skipped += 1
                self.stdout.write(
                    self.style.WARNING(
                        f"SKIP {brand.name}: ya tiene logo (usa --overwrite para reemplazar)."
                    )
                )
                continue

            matched += 1
            if dry_run:
                self.stdout.write(
                    f"DRY-RUN {brand.name} <- {image_path.name}"
                )
                continue

            content = image_path.read_bytes()
            mime_type = mimetypes.guess_type(image_path.name)[0] or "application/octet-stream"
            uploaded = SimpleUploadedFile(
                name=image_path.name,
                content=content,
                content_type=mime_type,
            )
            full, thumb = create_image_variants_from_upload(
                uploaded_file=uploaded,
                kind=ImageKind.BRAND_LOGO,
            )
            brand.logo_image = full
            brand.logo_image_full = full
            brand.logo_image_thumb = thumb
            brand.save(update_fields=["logo_image", "logo_image_full", "logo_image_thumb"])
            created += 1
            self.stdout.write(self.style.SUCCESS(f"OK {brand.name} <- {image_path.name}"))

        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS(f"Marcas con archivo encontrado: {matched}"))
        self.stdout.write(self.style.SUCCESS(f"Logos cargados/actualizados: {created}"))
        self.stdout.write(self.style.WARNING(f"Marcas con logo omitidas: {skipped}"))
        self.stdout.write(self.style.WARNING(f"Marcas sin archivo: {len(missing)}"))
        if missing:
            self.stdout.write("Sin archivo: " + ", ".join(missing))

