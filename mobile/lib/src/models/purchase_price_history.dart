class PurchasePriceHistoryPoint {
  const PurchasePriceHistoryPoint({
    required this.rawDate,
    required this.date,
    required this.amountRaw,
    required this.amount,
  });

  final String rawDate;
  final DateTime? date;
  final String amountRaw;
  final double amount;

  factory PurchasePriceHistoryPoint.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['date'] ?? '').toString();
    final amountRaw = (json['amount'] ?? '').toString();
    return PurchasePriceHistoryPoint(
      rawDate: rawDate,
      date: DateTime.tryParse(rawDate)?.toLocal(),
      amountRaw: amountRaw,
      amount: double.tryParse(amountRaw) ?? 0,
    );
  }
}

class PurchasePriceHistoryResponse {
  const PurchasePriceHistoryResponse({
    required this.inventoryItemId,
    required this.code,
    required this.brand,
    required this.currentPurchasePriceRaw,
    required this.currentPurchasePrice,
    required this.stats,
    required this.points,
  });

  final int inventoryItemId;
  final String code;
  final String brand;
  final String currentPurchasePriceRaw;
  final double currentPurchasePrice;
  final PurchasePriceStats? stats;
  final List<PurchasePriceHistoryPoint> points;

  factory PurchasePriceHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] is List
        ? json['points'] as List
        : const [];
    final points =
        rawPoints
            .whereType<Map>()
            .map(
              (item) => PurchasePriceHistoryPoint.fromJson(
                item.cast<String, dynamic>(),
              ),
            )
            .toList()
          ..sort((a, b) {
            final aDate = a.date;
            final bDate = b.date;
            if (aDate == null && bDate == null) {
              return 0;
            }
            if (aDate == null) {
              return -1;
            }
            if (bDate == null) {
              return 1;
            }
            return aDate.compareTo(bDate);
          });

    final currentRaw = (json['current_purchase_price'] ?? '').toString();
    final statsRaw = json['stats'];
    return PurchasePriceHistoryResponse(
      inventoryItemId: (json['inventory_item_id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      currentPurchasePriceRaw: currentRaw,
      currentPurchasePrice: double.tryParse(currentRaw) ?? 0,
      stats: statsRaw is Map<String, dynamic>
          ? PurchasePriceStats.fromJson(statsRaw)
          : statsRaw is Map
          ? PurchasePriceStats.fromJson(statsRaw.cast<String, dynamic>())
          : null,
      points: points,
    );
  }
}

class PurchasePriceStats {
  const PurchasePriceStats({
    required this.minRaw,
    required this.maxRaw,
    required this.avgRaw,
    required this.min,
    required this.max,
    required this.avg,
  });

  final String minRaw;
  final String maxRaw;
  final String avgRaw;
  final double min;
  final double max;
  final double avg;

  factory PurchasePriceStats.fromJson(Map<String, dynamic> json) {
    final minRaw = (json['min'] ?? '').toString();
    final maxRaw = (json['max'] ?? '').toString();
    final avgRaw = (json['avg'] ?? '').toString();
    return PurchasePriceStats(
      minRaw: minRaw,
      maxRaw: maxRaw,
      avgRaw: avgRaw,
      min: double.tryParse(minRaw) ?? 0,
      max: double.tryParse(maxRaw) ?? 0,
      avg: double.tryParse(avgRaw) ?? 0,
    );
  }
}
