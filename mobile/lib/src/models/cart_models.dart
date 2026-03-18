import 'package:image_picker/image_picker.dart';

enum CartProductType { tire, rim }

enum ManualLineType { service, accessory }

enum TradeInType { tire, rim }

class TradeInTireSpec {
  const TradeInTireSpec({
    this.ownerId,
    required this.brandId,
    required this.tireType,
    required this.rimDiameter,
    required this.origin,
    required this.plyRating,
    required this.treadType,
    required this.letterColor,
    required this.width,
    this.aspectRatio,
    this.model,
    this.suggestedSalePrice,
  });

  final int? ownerId;
  final int brandId;
  final String tireType;
  final String rimDiameter;
  final String origin;
  final String plyRating;
  final String treadType;
  final String letterColor;
  final int width;
  final int? aspectRatio;
  final String? model;
  final String? suggestedSalePrice;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'owner_id': ownerId,
      'brand_id': brandId,
      'tire_type': tireType,
      'rim_diameter': rimDiameter,
      'origin': origin,
      'ply_rating': plyRating,
      'tread_type': treadType,
      'letter_color': letterColor,
      'width': width,
      'aspect_ratio': aspectRatio,
      'model': model,
      'suggested_sale_price': suggestedSalePrice,
    };
    json.removeWhere((_, value) => value == null);
    return json;
  }
}

class TradeInRimSpec {
  const TradeInRimSpec({
    this.ownerId,
    required this.brandId,
    required this.internalCode,
    required this.rimDiameter,
    required this.holes,
    required this.widthIn,
    required this.material,
    required this.isSet,
    this.suggestedSalePrice,
  });

  final int? ownerId;
  final int brandId;
  final String internalCode;
  final String rimDiameter;
  final int holes;
  final int widthIn;
  final String material;
  final bool isSet;
  final String? suggestedSalePrice;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'owner_id': ownerId,
      'brand_id': brandId,
      'internal_code': internalCode,
      'rim_diameter': rimDiameter,
      'holes': holes,
      'width_in': widthIn,
      'material': material,
      'is_set': isSet,
      'suggested_sale_price': suggestedSalePrice,
    };
    json.removeWhere((_, value) => value == null);
    return json;
  }
}

class CartLineProduct {
  const CartLineProduct({
    required this.id,
    required this.inventoryItemId,
    required this.itemType,
    required this.displayCode,
    required this.brand,
    required this.ownerName,
    required this.quantity,
    required this.unitPrice,
    required this.availableStock,
  });

  final int id;
  final int inventoryItemId;
  final CartProductType itemType;
  final String displayCode;
  final String brand;
  final String ownerName;
  final int quantity;
  final double unitPrice;
  final int availableStock;

  double get lineTotal => quantity * unitPrice;

  CartLineProduct copyWith({int? quantity, double? unitPrice}) {
    return CartLineProduct(
      id: id,
      inventoryItemId: inventoryItemId,
      itemType: itemType,
      displayCode: displayCode,
      brand: brand,
      ownerName: ownerName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      availableStock: availableStock,
    );
  }
}

class CartLineManual {
  const CartLineManual({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    this.detailNote,
  });

  final int id;
  final ManualLineType type;
  final String description;
  final double amount;
  final String? detailNote;

  CartLineManual copyWith({
    ManualLineType? type,
    String? description,
    double? amount,
    String? detailNote,
  }) {
    return CartLineManual(
      id: id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      detailNote: detailNote ?? this.detailNote,
    );
  }
}

class TradeInLine {
  const TradeInLine({
    required this.id,
    required this.type,
    required this.quantity,
    required this.purchasePrice,
    required this.specsSummary,
    required this.notes,
    this.tireSpec,
    this.rimSpec,
    this.conditionPercent,
    this.needsRepair,
    this.rimPhoto,
  });

  final int id;
  final TradeInType type;
  final int quantity;
  final double purchasePrice;
  final String specsSummary;
  final String? notes;
  final TradeInTireSpec? tireSpec;
  final TradeInRimSpec? rimSpec;
  final int? conditionPercent;
  final bool? needsRepair;
  final XFile? rimPhoto;

  double get assessedValue => quantity * purchasePrice;

  bool get isComplete {
    if (purchasePrice <= 0 || quantity <= 0) {
      return false;
    }
    if (type == TradeInType.tire) {
      return conditionPercent != null && tireSpec != null;
    }
    return needsRepair != null && rimSpec != null;
  }

  String get summary {
    final condition = type == TradeInType.tire
        ? (conditionPercent != null
              ? 'Estado ${conditionPercent!}%'
              : 'Estado -')
        : (needsRepair == true ? 'Requiere reparación' : 'Sin reparación');
    return '$specsSummary | $condition';
  }

  TradeInLine copyWith({
    TradeInType? type,
    int? quantity,
    double? purchasePrice,
    String? specsSummary,
    String? notes,
    TradeInTireSpec? tireSpec,
    TradeInRimSpec? rimSpec,
    int? conditionPercent,
    bool? needsRepair,
    XFile? rimPhoto,
  }) {
    return TradeInLine(
      id: id,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      specsSummary: specsSummary ?? this.specsSummary,
      notes: notes ?? this.notes,
      tireSpec: tireSpec ?? this.tireSpec,
      rimSpec: rimSpec ?? this.rimSpec,
      conditionPercent: conditionPercent ?? this.conditionPercent,
      needsRepair: needsRepair ?? this.needsRepair,
      rimPhoto: rimPhoto ?? this.rimPhoto,
    );
  }
}
