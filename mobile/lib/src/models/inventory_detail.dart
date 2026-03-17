import 'owner.dart';
import 'image_ref.dart';

class InventoryDetail {
  const InventoryDetail({
    required this.inventoryItemId,
    required this.code,
    required this.tireType,
    required this.brand,
    required this.stock,
    required this.owner,
    required this.details,
    required this.purchasePrice,
    required this.suggestedSalePrice,
    required this.lastRestockAt,
    required this.createdAt,
    required this.updatedAt,
    required this.imageThumb,
    required this.image,
  });

  final int inventoryItemId;
  final String code;
  final String tireType;
  final String brand;
  final int stock;
  final Owner? owner;
  final String details;
  final String purchasePrice;
  final String suggestedSalePrice;
  final String lastRestockAt;
  final String createdAt;
  final String updatedAt;
  final ImageRef? imageThumb;
  final ImageRef? image;

  factory InventoryDetail.fromJson(Map<String, dynamic> json) {
    final ownerRaw = json['owner'];
    final imageThumbRaw = json['image_thumb'];
    final imageRaw = json['image'];
    return InventoryDetail(
      inventoryItemId: (json['inventory_item_id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      tireType: (json['tire_type'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      owner: ownerRaw is Map<String, dynamic> ? Owner.fromJson(ownerRaw) : null,
      details: (json['details'] ?? '').toString(),
      purchasePrice: (json['purchase_price'] ?? '').toString(),
      suggestedSalePrice: (json['suggested_sale_price'] ?? '').toString(),
      lastRestockAt: (json['last_restock_at'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      imageThumb: imageThumbRaw is Map<String, dynamic>
          ? ImageRef.fromJson(imageThumbRaw)
          : null,
      image: imageRaw is Map<String, dynamic>
          ? ImageRef.fromJson(imageRaw)
          : null,
    );
  }
}
