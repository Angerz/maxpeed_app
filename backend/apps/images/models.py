from django.db import models


class ImageKind(models.TextChoices):
    BRAND_LOGO = "BRAND_LOGO", "Brand Logo"
    RIM_PHOTO = "RIM_PHOTO", "Rim Photo"


class ImageAsset(models.Model):
    kind = models.CharField(max_length=20, choices=ImageKind.choices)
    mime_type = models.CharField(max_length=100)
    data = models.BinaryField()
    sha256 = models.CharField(max_length=64, null=True, blank=True)
    size_bytes = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at", "-id"]
        indexes = [
            models.Index(fields=["kind", "created_at"]),
            models.Index(fields=["sha256"]),
        ]

    def __str__(self) -> str:
        return f"{self.kind} #{self.id}"
