class BrandOption {
  const BrandOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory BrandOption.fromJson(Map<String, dynamic> json) {
    return BrandOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['label'] ?? '').toString(),
    );
  }

  @override
  String toString() => name;
}
