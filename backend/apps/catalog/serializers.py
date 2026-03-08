from rest_framework import serializers

from .choices import (
    LetterColor,
    Origin,
    PlyRating,
    RimDiameter,
    RimHoles,
    RimMaterial,
    RimWidthIn,
    TireType,
    TreadType,
)
from .models import Brand


SPANISH_CHOICE_LABELS = {
    "tire_type": {
        "RADIAL": "Radial",
        "CARGO": "Carga",
        "MILLIMETRIC": "Milimétrica",
        "CONVENTIONAL": "Convencional",
    },
    "rim_diameter": {
        "R12": "R12",
        "R13": "R13",
        "R14": "R14",
        "R15": "R15",
        "R16": "R16",
        "R17": "R17",
        "R18": "R18",
        "R19": "R19",
        "R20": "R20",
        "R21": "R21",
        "R22": "R22",
    },
    "origin": {
        "CHINA": "China",
        "THAILAND": "Tailandesa",
        "JAPAN": "Japonesa",
        "KOREA": "Coreana",
        "AMERICAN": "Americana",
        "INDIA": "India",
        "MEXICAN": "Mexicana",
        "EUROPE": "Europea",
        "PERUVIAN": "Peruana",
        "OTHER": "Otra",
    },
    "ply_rating": {
        "PR2": "2PR",
        "PR4": "4PR",
        "PR6": "6PR",
        "PR8": "8PR",
        "PR10": "10PR",
        "PR12": "12PR",
        "PR14": "14PR",
        "PR16": "16PR",
        "PR18": "18PR",
        "PR20": "20PR",
        "PR22": "22PR",
    },
    "tread_type": {
        "LINEAR": "Lineal",
        "AT": "AT",
        "AT2": "AT2",
        "AT3": "AT3",
        "HT": "HT",
        "MT": "MT",
        "RT": "RT",
        "LT": "LT",
        "HIGHWAY": "Pistera",
        "SPORT": "Deportiva",
        "MIXED": "Mixta",
    },
    "letter_color": {
        "BLACK": "Negro",
        "WHITE": "Blanco",
    },
    "rim_holes": {
        4: "4 huecos",
        5: "5 huecos",
        6: "6 huecos",
    },
    "rim_width_in": {
        5: "5 pulgadas",
        6: "6 pulgadas",
        7: "7 pulgadas",
        8: "8 pulgadas",
        9: "9 pulgadas",
        10: "10 pulgadas",
        11: "11 pulgadas",
        12: "12 pulgadas",
    },
    "rim_material": {
        "ALUMINUM": "Aluminio",
        "IRON": "Fierro",
    },
}


def serialize_choices(choice_enum, label_map):
    return [
        {"value": value, "label": label_map.get(value, label)}
        for value, label in choice_enum.choices
    ]


class CatalogChoicesSerializer(serializers.Serializer):
    tire_type = serializers.ListField()
    rim_diameter = serializers.ListField()
    origin = serializers.ListField()
    ply_rating = serializers.ListField()
    tread_type = serializers.ListField()
    letter_color = serializers.ListField()
    rim_holes = serializers.ListField()
    rim_width_in = serializers.ListField()
    rim_material = serializers.ListField()
    rim_is_set = serializers.ListField()
    owners = serializers.ListField()

    @classmethod
    def build_payload(cls, *, owners):
        return {
            "tire_type": serialize_choices(TireType, SPANISH_CHOICE_LABELS["tire_type"]),
            "rim_diameter": serialize_choices(RimDiameter, SPANISH_CHOICE_LABELS["rim_diameter"]),
            "origin": serialize_choices(Origin, SPANISH_CHOICE_LABELS["origin"]),
            "ply_rating": serialize_choices(PlyRating, SPANISH_CHOICE_LABELS["ply_rating"]),
            "tread_type": serialize_choices(TreadType, SPANISH_CHOICE_LABELS["tread_type"]),
            "letter_color": serialize_choices(LetterColor, SPANISH_CHOICE_LABELS["letter_color"]),
            "rim_holes": serialize_choices(RimHoles, SPANISH_CHOICE_LABELS["rim_holes"]),
            "rim_width_in": serialize_choices(RimWidthIn, SPANISH_CHOICE_LABELS["rim_width_in"]),
            "rim_material": serialize_choices(RimMaterial, SPANISH_CHOICE_LABELS["rim_material"]),
            "rim_is_set": [
                {"value": True, "label": "Juego"},
                {"value": False, "label": "Suelto"},
            ],
            "owners": owners,
        }


class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ("id", "name")


class CatalogServiceSerializer(serializers.Serializer):
    value = serializers.CharField()
    label = serializers.CharField()
