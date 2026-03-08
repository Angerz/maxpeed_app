class ServiceOption {
  const ServiceOption({
    required this.name,
    this.id,
  });

  final int? id;
  final String name;

  factory ServiceOption.fromDynamic(dynamic raw) {
    if (raw is String) {
      return ServiceOption(name: raw.trim());
    }
    if (raw is Map<String, dynamic>) {
      final id = (raw['id'] as num?)?.toInt();
      final name = (raw['name'] ?? raw['label'] ?? raw['description'] ?? '').toString().trim();
      return ServiceOption(id: id, name: name);
    }
    return const ServiceOption(name: '');
  }
}

