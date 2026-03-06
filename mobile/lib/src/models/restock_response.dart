class RestockResponse {
  const RestockResponse({
    required this.stockBefore,
    required this.stockAfter,
    required this.purchasePriceCurrent,
    required this.suggestedSalePriceCurrent,
    required this.lastRestockAt,
  });

  final int stockBefore;
  final int stockAfter;
  final String purchasePriceCurrent;
  final String suggestedSalePriceCurrent;
  final String? lastRestockAt;

  factory RestockResponse.fromJson(Map<String, dynamic> json) {
    return RestockResponse(
      stockBefore: (json['stock_before'] as num?)?.toInt() ?? 0,
      stockAfter: (json['stock_after'] as num?)?.toInt() ?? 0,
      purchasePriceCurrent: (json['purchase_price_current'] ?? json['purchase_price'] ?? '').toString(),
      suggestedSalePriceCurrent: (json['suggested_sale_price_current'] ?? json['suggested_sale_price'] ?? '').toString(),
      lastRestockAt: json['last_restock_at']?.toString(),
    );
  }
}
