enum CartProductType { tire, rim }

enum ManualLineType { service, accessory }

enum TradeInType { tire, rim }

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

  CartLineProduct copyWith({
    int? quantity,
    double? unitPrice,
  }) {
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
    required this.assessedValue,
    required this.notes,
    this.conditionPercent,
    this.needsRepair,
  });

  final int id;
  final TradeInType type;
  final double assessedValue;
  final String? notes;
  final int? conditionPercent;
  final bool? needsRepair;

  String get summary {
    if (type == TradeInType.tire) {
      final condition = conditionPercent != null ? 'Estado ${conditionPercent!}%' : 'Estado -';
      return 'Llanta usada | $condition';
    }
    final repairLabel = needsRepair == true ? 'Requiere reparación' : 'Sin reparación';
    return 'Aro usado | $repairLabel';
  }

  TradeInLine copyWith({
    TradeInType? type,
    double? assessedValue,
    String? notes,
    int? conditionPercent,
    bool? needsRepair,
  }) {
    return TradeInLine(
      id: id,
      type: type ?? this.type,
      assessedValue: assessedValue ?? this.assessedValue,
      notes: notes ?? this.notes,
      conditionPercent: conditionPercent ?? this.conditionPercent,
      needsRepair: needsRepair ?? this.needsRepair,
    );
  }
}
