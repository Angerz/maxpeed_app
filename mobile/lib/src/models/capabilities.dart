class Capabilities {
  const Capabilities(this.values);

  final Map<String, bool> values;

  bool can(String capability) => values[capability] == true;

  factory Capabilities.fromDynamic(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Capabilities(
        raw.map((key, value) => MapEntry(key, value == true)),
      );
    }
    if (raw is Map) {
      return Capabilities(
        raw.map(
          (key, value) => MapEntry(key.toString(), value == true),
        ),
      );
    }
    return const Capabilities(<String, bool>{});
  }

  Map<String, dynamic> toJson() => values;
}
