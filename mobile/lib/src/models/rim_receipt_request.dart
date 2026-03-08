class RimReceiptRequest {
  const RimReceiptRequest({
    required this.ownerId,
    required this.brandId,
    required this.internalCode,
    required this.rimDiameter,
    required this.holes,
    required this.widthIn,
    required this.material,
    required this.isSet,
    required this.quantity,
    required this.unitPurchasePrice,
    this.suggestedSalePrice,
    this.notes,
  });

  final int ownerId;
  final int brandId;
  final String internalCode;
  final String rimDiameter;
  final int holes;
  final int widthIn;
  final String material;
  final bool isSet;
  final int quantity;
  final String unitPurchasePrice;
  final String? suggestedSalePrice;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'brand_id': brandId,
      'internal_code': internalCode,
      'rim_diameter': rimDiameter,
      'holes': holes,
      'width_in': widthIn,
      'material': material,
      'is_set': isSet,
      'quantity': quantity,
      'unit_purchase_price': unitPurchasePrice,
      'suggested_sale_price': suggestedSalePrice,
      'notes': notes,
    };
  }
}
