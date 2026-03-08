import 'dart:typed_data';

import 'rim_photo_storage_base.dart';

RimPhotoStorage createRimPhotoStorage() => _RimPhotoStorageStub();

class _RimPhotoStorageStub implements RimPhotoStorage {
  @override
  bool get supportsPersistentStorage => false;

  @override
  Future<void> deletePhoto(String internalCode) async {}

  @override
  Future<Uint8List?> readPhotoBytes(String internalCode) async => null;

  @override
  Future<void> savePhotoBytes({
    required String internalCode,
    required Uint8List bytes,
  }) async {}
}
