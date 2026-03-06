import 'inventory_card_item.dart';

class InventoryGroupResponse {
  const InventoryGroupResponse({required this.groups});

  final Map<String, List<InventoryCardItem>> groups;

  factory InventoryGroupResponse.fromJson(Map<String, dynamic> json) {
    final parsed = <String, List<InventoryCardItem>>{};

    for (final entry in json.entries) {
      final key = entry.key;
      final rawItems = entry.value;
      if (rawItems is! List) {
        parsed[key] = const [];
        continue;
      }

      final items = rawItems
          .whereType<Map>()
          .map((item) => InventoryCardItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      parsed[key] = items;
    }

    return InventoryGroupResponse(groups: parsed);
  }
}
