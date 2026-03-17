class ImageRef {
  const ImageRef({required this.id, required this.url});

  final int id;
  final String url;

  bool get hasUrl => url.trim().isNotEmpty;

  factory ImageRef.fromJson(Map<String, dynamic> json) {
    return ImageRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: (json['url'] ?? '').toString(),
    );
  }
}
