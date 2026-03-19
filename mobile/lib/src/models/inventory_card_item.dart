import 'owner.dart';
import 'image_ref.dart';

class InventoryCardItem {
  const InventoryCardItem({
    required this.inventoryItemId,
    required this.code,
    required this.brand,
    required this.stock,
    required this.details,
    required this.owner,
    required this.imageThumb,
    required this.image,
    required this.conditionLabel,
  });

  final int inventoryItemId;
  final String code;
  final String brand;
  final int stock;
  final String details;
  final Owner? owner;
  final ImageRef? imageThumb;
  final ImageRef? image;
  final String? conditionLabel;

  factory InventoryCardItem.fromJson(Map<String, dynamic> json) {
    final ownerRaw = json['owner'];
    final imageThumbRaw = json['image_thumb'];
    final imageRaw = json['image'];
    final conditionRaw = json['condition_label']?.toString().trim();
    return InventoryCardItem(
      inventoryItemId: (json['inventory_item_id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      details: (json['details'] ?? '').toString(),
      owner: ownerRaw is Map<String, dynamic> ? Owner.fromJson(ownerRaw) : null,
      imageThumb: imageThumbRaw is Map<String, dynamic>
          ? ImageRef.fromJson(imageThumbRaw)
          : null,
      image: imageRaw is Map<String, dynamic>
          ? ImageRef.fromJson(imageRaw)
          : null,
      conditionLabel: (conditionRaw == null || conditionRaw.isEmpty)
          ? null
          : conditionRaw,
    );
  }
}
