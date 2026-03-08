class SaleLineRequest {
  const SaleLineRequest({
    required this.lineType,
    this.inventoryItemId,
    this.description,
    this.quantity,
    this.unitPrice,
    this.discount,
    this.assessedValue,
    this.tireConditionPercent,
    this.rimRequiresRepair,
  });

  final String lineType;
  final int? inventoryItemId;
  final String? description;
  final int? quantity;
  final String? unitPrice;
  final String? discount;
  final String? assessedValue;
  final int? tireConditionPercent;
  final bool? rimRequiresRepair;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'line_type': lineType,
      'inventory_item_id': inventoryItemId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'assessed_value': assessedValue,
      'tire_condition_percent': tireConditionPercent,
      'rim_requires_repair': rimRequiresRepair,
    };
    json.removeWhere((_, value) => value == null);
    return json;
  }
}

class SaleCreateRequest {
  const SaleCreateRequest({
    required this.discountTotal,
    required this.lines,
    this.notes,
  });

  final String discountTotal;
  final String? notes;
  final List<SaleLineRequest> lines;

  Map<String, dynamic> toJson() {
    return {
      'discount_total': discountTotal,
      'notes': notes,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }
}

class SaleCreateResponse {
  const SaleCreateResponse({
    required this.saleId,
    required this.subtotal,
    required this.discountTotal,
    required this.tradeinCreditTotal,
    required this.total,
    required this.totalDue,
  });

  final int saleId;
  final String subtotal;
  final String discountTotal;
  final String tradeinCreditTotal;
  final String total;
  final String totalDue;

  factory SaleCreateResponse.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] is Map<String, dynamic>
        ? json['totals'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return SaleCreateResponse(
      saleId: (json['sale_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      subtotal: (totals['subtotal'] ?? '').toString(),
      discountTotal: (totals['discount_total'] ?? '').toString(),
      tradeinCreditTotal: (totals['tradein_credit_total'] ?? '').toString(),
      total: (totals['total'] ?? '').toString(),
      totalDue: (totals['total_due'] ?? '').toString(),
    );
  }
}

class SaleListItem {
  const SaleListItem({
    required this.id,
    required this.soldAt,
    required this.total,
    required this.totalDue,
    required this.tradeinCreditTotal,
    required this.itemCount,
  });

  final int id;
  final String soldAt;
  final String total;
  final String totalDue;
  final String tradeinCreditTotal;
  final int itemCount;

  factory SaleListItem.fromJson(Map<String, dynamic> json) {
    return SaleListItem(
      id: (json['id'] as num?)?.toInt() ?? (json['sale_id'] as num?)?.toInt() ?? 0,
      soldAt: (json['sold_at'] ?? json['created_at'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      totalDue: (json['total_due'] ?? '').toString(),
      tradeinCreditTotal: (json['tradein_credit_total'] ?? '').toString(),
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SaleDetailLine {
  const SaleDetailLine({
    required this.lineType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.assessedValue,
    required this.lineTotal,
  });

  final String lineType;
  final String description;
  final int quantity;
  final String unitPrice;
  final String assessedValue;
  final String lineTotal;

  static String _extractDescription(Map<String, dynamic> json) {
    final direct = json['description'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    final catalogSnapshot = json['catalog_item_snapshot'];
    if (catalogSnapshot is Map<String, dynamic>) {
      final code = catalogSnapshot['code'];
      if (code != null && code.toString().trim().isNotEmpty) {
        return code.toString();
      }
    }

    final inventorySnapshot = json['inventory_item_snapshot'];
    if (inventorySnapshot is Map<String, dynamic>) {
      final code = inventorySnapshot['code'];
      if (code != null && code.toString().trim().isNotEmpty) {
        return code.toString();
      }
    }

    return '-';
  }

  factory SaleDetailLine.fromJson(Map<String, dynamic> json) {
    return SaleDetailLine(
      lineType: (json['line_type'] ?? '').toString(),
      description: _extractDescription(json),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] ?? '').toString(),
      assessedValue: (json['assessed_value'] ?? '').toString(),
      lineTotal: (json['line_total'] ?? '').toString(),
    );
  }
}

class SaleDetail {
  const SaleDetail({
    required this.id,
    required this.soldAt,
    required this.notes,
    required this.subtotal,
    required this.discountTotal,
    required this.tradeinCreditTotal,
    required this.total,
    required this.totalDue,
    required this.lines,
  });

  final int id;
  final String soldAt;
  final String notes;
  final String subtotal;
  final String discountTotal;
  final String tradeinCreditTotal;
  final String total;
  final String totalDue;
  final List<SaleDetailLine> lines;

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] is List ? json['lines'] as List : <dynamic>[];
    return SaleDetail(
      id: (json['id'] as num?)?.toInt() ?? (json['sale_id'] as num?)?.toInt() ?? 0,
      soldAt: (json['sold_at'] ?? json['created_at'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      subtotal: (json['subtotal'] ?? '').toString(),
      discountTotal: (json['discount_total'] ?? '').toString(),
      tradeinCreditTotal: (json['tradein_credit_total'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      totalDue: (json['total_due'] ?? '').toString(),
      lines: rawLines
          .whereType<Map>()
          .map((item) => SaleDetailLine.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}
