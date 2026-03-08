import 'dart:typed_data';

abstract class RimPhotoStorage {
  bool get supportsPersistentStorage;

  Future<Uint8List?> readPhotoBytes(String internalCode);

  Future<void> savePhotoBytes({
    required String internalCode,
    required Uint8List bytes,
  });

  Future<void> deletePhoto(String internalCode);
}

String sanitizeRimCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final upper = trimmed.toUpperCase().replaceAll(RegExp(r'\s+'), '_');
  final safe = upper.replaceAll(RegExp(r'[^A-Z0-9_.-]'), '');
  return safe.isEmpty ? 'RIM' : safe;
}
