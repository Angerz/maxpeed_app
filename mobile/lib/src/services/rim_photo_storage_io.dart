import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'rim_photo_storage_base.dart';

RimPhotoStorage createRimPhotoStorage() => _RimPhotoStorageIo();

class _RimPhotoStorageIo implements RimPhotoStorage {
  @override
  bool get supportsPersistentStorage => true;

  Future<Directory> _rimsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/rims');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _fileForCode(String internalCode) async {
    final code = sanitizeRimCode(internalCode);
    final dir = await _rimsDir();
    return File('${dir.path}/$code.jpg');
  }

  @override
  Future<Uint8List?> readPhotoBytes(String internalCode) async {
    final file = await _fileForCode(internalCode);
    if (!await file.exists()) {
      return null;
    }
    try {
      return file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> savePhotoBytes({
    required String internalCode,
    required Uint8List bytes,
  }) async {
    final file = await _fileForCode(internalCode);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> deletePhoto(String internalCode) async {
    final file = await _fileForCode(internalCode);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
