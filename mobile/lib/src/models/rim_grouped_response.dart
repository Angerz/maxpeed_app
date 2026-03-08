import 'rim_inventory_card_item.dart';

class RimGroupedResponse {
  const RimGroupedResponse({required this.groups});

  final Map<String, List<RimInventoryCardItem>> groups;

  factory RimGroupedResponse.fromJson(Map<String, dynamic> json) {
    final parsed = <String, List<RimInventoryCardItem>>{};

    for (final entry in json.entries) {
      final key = entry.key;
      final rawItems = entry.value;
      if (rawItems is! List) {
        parsed[key] = const [];
        continue;
      }

      final items = rawItems
          .whereType<Map>()
          .map((item) => RimInventoryCardItem.fromJson(item.cast<String, dynamic>()))
          .toList();
      parsed[key] = items;
    }

    return RimGroupedResponse(groups: parsed);
  }
}
