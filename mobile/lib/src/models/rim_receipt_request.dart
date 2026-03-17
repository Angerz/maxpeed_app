import 'dart:typed_data';

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
    this.rimPhotoBytes,
    this.rimPhotoFilename,
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
  final Uint8List? rimPhotoBytes;
  final String? rimPhotoFilename;

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

  Map<String, String> toFields() {
    final fields = <String, String>{
      'owner_id': ownerId.toString(),
      'brand_id': brandId.toString(),
      'internal_code': internalCode,
      'rim_diameter': rimDiameter,
      'holes': holes.toString(),
      'width_in': widthIn.toString(),
      'material': material,
      'is_set': isSet.toString(),
      'quantity': quantity.toString(),
      'unit_purchase_price': unitPurchasePrice,
    };
    if (suggestedSalePrice != null && suggestedSalePrice!.trim().isNotEmpty) {
      fields['suggested_sale_price'] = suggestedSalePrice!.trim();
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      fields['notes'] = notes!.trim();
    }
    return fields;
  }
}
