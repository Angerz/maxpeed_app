import 'owner.dart';
import 'image_ref.dart';

class RimInventoryCardItem {
  const RimInventoryCardItem({
    required this.inventoryItemId,
    required this.internalCode,
    required this.brand,
    required this.stock,
    required this.details,
    required this.owner,
    required this.image,
  });

  final int inventoryItemId;
  final String internalCode;
  final String brand;
  final int stock;
  final String details;
  final Owner? owner;
  final ImageRef? image;

  factory RimInventoryCardItem.fromJson(Map<String, dynamic> json) {
    final ownerRaw = json['owner'];
    final imageRaw = json['image'];
    return RimInventoryCardItem(
      inventoryItemId: (json['inventory_item_id'] as num?)?.toInt() ?? 0,
      internalCode: (json['internal_code'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      details: (json['details'] ?? '').toString(),
      owner: ownerRaw is Map<String, dynamic> ? Owner.fromJson(ownerRaw) : null,
      image: imageRaw is Map<String, dynamic>
          ? ImageRef.fromJson(imageRaw)
          : null,
    );
  }
}
