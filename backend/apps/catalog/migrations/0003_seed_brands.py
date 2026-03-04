from django.db import migrations


BRAND_NAMES = [
    "AEOLUS",
    "ALTENZO",
    "AMERICA",
    "ANCHEE",
    "ANNAITE",
    "ANTARES",
    "AOQISHI (MAXTREK)",
    "APLUS",
    "ARIVO",
    "AUSTONE",
    "BCT",
    "BEARWAY",
    "BF GOODRICH",
    "BRIDGESTONE",
    "CENTARA",
    "CENTELLA",
    "CHAOYANG",
    "CHENGSHAN",
    "CITY STAR",
    "COMFORSER",
    "COMPASAL",
    "CONTINENTAL",
    "COOPER",
    "CROSSLEADER",
    "CST",
    "DEESTONE",
    "DELINTE",
    "DOUBLE STAR",
    "DUNLOP",
    "DURATURN",
    "FARROAD",
    "FEDERAL",
    "FIRESTONE",
    "FORTUNE",
    "GENERAL",
    "GOODYEAR",
    "GT RADIAL",
    "HABILEAD",
    "HAIDA",
    "HANKOOK",
    "HIFLY",
    "HILO",
    "IMPERIAL",
    "INDUS",
    "JK TORNEL",
    "JK TYRE",
    "KAPSEN",
    "LEAO",
    "LIMA CAUCHO",
    "LING LONG",
    "LUXXAN",
    "MARSHAL",
    "MAXTREK",
    "MAXXIS",
    "MEMBAT",
    "MICHELIN",
    "MRF",
    "MRL",
    "ONYX",
    "PACE",
    "PANTERA",
    "PIRELLI",
    "PRIMEWELL",
    "PRINX",
    "RADAR",
    "RAPIDASH",
    "ROADCRUZA",
    "ROCKBLADE",
    "RUNSTONE",
    "RYDANZ",
    "SENTURY",
    "SUNNY",
    "SUPERCARGO",
    "TERAFLEX",
    "TERRUS",
    "TORNEL",
    "TOURADOR",
    "TRAZANO",
    "TRIANGLE",
    "ULTRAFORCE",
    "VIKRANT",
    "WELLPLUS",
    "WESTLAKE",
    "WIDEWAY",
    "YUSTA",
    "ZETA",
    "ZEXTOUR",
]


def seed_brands(apps, schema_editor):
    Brand = apps.get_model("catalog", "Brand")
    existing_names = set(Brand.objects.values_list("name", flat=True))

    Brand.objects.bulk_create(
        [Brand(name=name) for name in BRAND_NAMES if name not in existing_names],
        ignore_conflicts=True,
    )


class Migration(migrations.Migration):

    dependencies = [
        ("catalog", "0002_catalogitem_sku_and_service_categories"),
    ]

    operations = [
        migrations.RunPython(seed_brands, migrations.RunPython.noop),
    ]
