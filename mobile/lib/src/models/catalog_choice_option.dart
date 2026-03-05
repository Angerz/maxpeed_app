class CatalogChoiceOption {
  const CatalogChoiceOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  factory CatalogChoiceOption.fromJson(Map<String, dynamic> json) {
    return CatalogChoiceOption(
      value: (json['value'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}
