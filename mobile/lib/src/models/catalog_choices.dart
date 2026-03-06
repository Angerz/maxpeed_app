import 'catalog_choice_option.dart';
import 'owner.dart';

class CatalogChoices {
  const CatalogChoices({
    required this.tireTypes,
    required this.rimDiameters,
    required this.origins,
    required this.plyRatings,
    required this.treadTypes,
    required this.letterColors,
    required this.owners,
  });

  final List<CatalogChoiceOption> tireTypes;
  final List<CatalogChoiceOption> rimDiameters;
  final List<CatalogChoiceOption> origins;
  final List<CatalogChoiceOption> plyRatings;
  final List<CatalogChoiceOption> treadTypes;
  final List<CatalogChoiceOption> letterColors;
  final List<Owner> owners;

  factory CatalogChoices.fromJson(Map<String, dynamic> json) {
    List<CatalogChoiceOption> parseList(String key) {
      final raw = json[key];
      if (raw is! List) {
        return const [];
      }
      return raw
          .whereType<Map>()
          .map((item) => CatalogChoiceOption.fromJson(item.cast<String, dynamic>()))
          .toList();
    }

    return CatalogChoices(
      tireTypes: parseList('tire_type'),
      rimDiameters: parseList('rim_diameter'),
      origins: parseList('origin'),
      plyRatings: parseList('ply_rating'),
      treadTypes: parseList('tread_type'),
      letterColors: parseList('letter_color'),
      owners: (json['owners'] is List)
          ? (json['owners'] as List)
              .whereType<Map>()
              .map((item) => Owner.fromJson(item.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}
