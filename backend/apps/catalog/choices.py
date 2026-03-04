from django.db import models


class ItemKind(models.TextChoices):
    MERCHANDISE = "MERCHANDISE", "Merchandise"
    SERVICE = "SERVICE", "Service"


class ProductCategory(models.TextChoices):
    TIRE = "TIRE", "Tire"
    RIM = "RIM", "Rim"
    ACCESSORY = "ACCESSORY", "Accessory"
    RIM_REPAIR = "RIM_REPAIR", "Rim Repair"
    RIM_BALANCE = "RIM_BALANCE", "Rim Balance"
    PAINTING = "PAINTING", "Painting"
    TIRE_MOUNTING = "TIRE_MOUNTING", "Tire Mounting"
    TIRE_PATCHING = "TIRE_PATCHING", "Tire Patching"
    SERVICE_GENERAL = "SERVICE_GENERAL", "General Service"


class Origin(models.TextChoices):
    CHINA = "CHINA", "China"
    THAILAND = "THAILAND", "Thailand"
    JAPAN = "JAPAN", "Japan"
    KOREA = "KOREA", "Korea"
    AMERICAN = "AMERICAN", "American"
    INDIA = "INDIA", "India"
    # BRAZIL = "BRAZIL", "Brazil"
    MEXICAN = "MEXICAN", "Mexican"
    EUROPE = "EUROPE", "Europe"
    PERUVIAN = "PERUVIAN", "Peruvian"
    OTHER = "OTHER", "Other"


class TireType(models.TextChoices):
    RADIAL = "RADIAL", "Radial"
    CARGO = "CARGO", "Cargo"
    MILLIMETRIC = "MILLIMETRIC", "Millimetric"
    CONVENTIONAL = "CONVENTIONAL", "Conventional"


class RimDiameter(models.TextChoices):
    R12 = "R12", "R12"
    R13 = "R13", "R13"
    R14 = "R14", "R14"
    R15 = "R15", "R15"
    R16 = "R16", "R16"
    R17 = "R17", "R17"
    R18 = "R18", "R18"
    R19 = "R19", "R19"
    R20 = "R20", "R20"
    R21 = "R21", "R21"
    R22 = "R22", "R22"


class PlyRating(models.TextChoices):
    PR2 = "PR2", "PR2"
    PR4 = "PR4", "PR4"
    PR6 = "PR6", "PR6"
    PR8 = "PR8", "PR8"
    PR10 = "PR10", "PR10"
    PR12 = "PR12", "PR12"
    PR14 = "PR14", "PR14"
    PR16 = "PR16", "PR16"
    PR18 = "PR18", "PR18"
    PR20 = "PR20", "PR20"
    PR22 = "PR22", "PR22"


class TreadType(models.TextChoices):
    LINEAR = "LINEAR", "Linear"
    AT = "AT", "A/T"
    AT2 = "AT2", "A/T 2"
    AT3 = "AT3", "A/T 3"
    HT = "HT", "H/T"
    MT = "MT", "M/T"
    RT = "RT", "R/T"
    LT = "LT", "L/T"
    HIGHWAY = "HIGHWAY", "Highway"
    SPORT = "SPORT", "Sport"
    MIXED = "MIXED", "Mixed"


class LetterColor(models.TextChoices):
    BLACK = "BLACK", "Black"
    WHITE = "WHITE", "White"
    # RED = "RED", "Red"
    # YELLOW = "YELLOW", "Yellow"
