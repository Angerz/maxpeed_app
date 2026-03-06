class Owner {
  const Owner({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: (json['id'] as num?)?.toInt() ?? (json['value'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['label'] ?? '').toString(),
    );
  }

  @override
  String toString() => name;
}
