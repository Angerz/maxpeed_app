class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final rawResults = json['results'] is List ? json['results'] as List : <dynamic>[];
    return PaginatedResponse<T>(
      count: (json['count'] as num?)?.toInt() ?? rawResults.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: rawResults
          .whereType<Map>()
          .map((item) => mapper(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

