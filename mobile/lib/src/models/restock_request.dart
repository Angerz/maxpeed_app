class RestockRequest {
  const RestockRequest({
    required this.quantity,
    required this.unitPurchasePrice,
    this.suggestedSalePrice,
    this.notes,
  });

  final int quantity;
  final String unitPurchasePrice;
  final String? suggestedSalePrice;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'unit_purchase_price': unitPurchasePrice,
      'suggested_sale_price': suggestedSalePrice,
      'notes': notes,
    };
  }
}
