class SaleLineRequest {
  const SaleLineRequest({
    required this.lineType,
    this.inventoryItemId,
    this.description,
    this.notes,
    this.quantity,
    this.unitPrice,
    this.discount,
    this.assessedValue,
    this.tireConditionPercent,
    this.rimRequiresRepair,
    this.tire,
    this.rim,
  });

  final String lineType;
  final int? inventoryItemId;
  final String? description;
  final String? notes;
  final int? quantity;
  final String? unitPrice;
  final String? discount;
  final String? assessedValue;
  final int? tireConditionPercent;
  final bool? rimRequiresRepair;
  final Map<String, dynamic>? tire;
  final Map<String, dynamic>? rim;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'line_type': lineType,
      'inventory_item_id': inventoryItemId,
      'description': description,
      'notes': notes,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'assessed_value': assessedValue,
      'tire_condition_percent': tireConditionPercent,
      'rim_requires_repair': rimRequiresRepair,
      'tire': tire,
      'rim': rim,
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
      saleId:
          (json['sale_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
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
      id:
          (json['id'] as num?)?.toInt() ??
          (json['sale_id'] as num?)?.toInt() ??
          0,
      soldAt: (json['sold_at'] ?? json['created_at'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      totalDue: (json['total_due'] ?? '').toString(),
      tradeinCreditTotal: (json['tradein_credit_total'] ?? '').toString(),
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesDayStat {
  const SalesDayStat({
    required this.date,
    required this.total,
    required this.salesCount,
  });

  final String date;
  final String total;
  final int salesCount;

  factory SalesDayStat.fromJson(Map<String, dynamic> json) {
    return SalesDayStat(
      date: (json['date'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesSummary {
  const SalesSummary({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    this.bestDay,
    this.worstDay,
  });

  final String startDate;
  final String endDate;
  final String totalRevenue;
  final SalesDayStat? bestDay;
  final SalesDayStat? worstDay;

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    final bestRaw = json['best_day'];
    final worstRaw = json['worst_day'];
    return SalesSummary(
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      totalRevenue: (json['total_revenue'] ?? '').toString(),
      bestDay: bestRaw is Map<String, dynamic>
          ? SalesDayStat.fromJson(bestRaw)
          : null,
      worstDay: worstRaw is Map<String, dynamic>
          ? SalesDayStat.fromJson(worstRaw)
          : null,
    );
  }
}

class SalesListResponse {
  const SalesListResponse({
    required this.summary,
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final SalesSummary? summary;
  final int count;
  final String? next;
  final String? previous;
  final List<SaleListItem> results;

  factory SalesListResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] is List
        ? json['results'] as List
        : <dynamic>[];
    final summaryRaw = json['summary'];
    return SalesListResponse(
      summary: summaryRaw is Map<String, dynamic>
          ? SalesSummary.fromJson(summaryRaw)
          : null,
      count: (json['count'] as num?)?.toInt() ?? rawResults.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .whereType<Map>()
          .map((item) => SaleListItem.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class SaleDetailLine {
  const SaleDetailLine({
    required this.code,
    required this.brand,
    required this.lineType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.assessedValue,
    required this.lineTotal,
  });

  final String code;
  final String brand;
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
    final extractedDescription = _extractDescription(json);
    return SaleDetailLine(
      code: (json['code'] ?? extractedDescription).toString(),
      brand: (json['brand'] ?? '-').toString(),
      lineType: (json['line_type'] ?? '').toString(),
      description: extractedDescription,
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
    final rawLines = json['lines'] is List
        ? json['lines'] as List
        : <dynamic>[];
    return SaleDetail(
      id:
          (json['id'] as num?)?.toInt() ??
          (json['sale_id'] as num?)?.toInt() ??
          0,
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
