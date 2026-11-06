import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:core_network/core_network.dart';

class CameraService {
  CameraService(this._picker);

  final ImagePicker _picker;

  Future<Result<File>> capture({
    ImageSource source = ImageSource.camera,
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      final picked = await _pick(
        source: source,
        maxWidth: maxWidth,
        quality: quality,
      );

      return _resultFor(picked);
    } on Exception catch (error) {
      return Err(PermissionFailure('Камера недоступна: $error'));
    }
  }

  Future<XFile?> _pick({
    required ImageSource source,
    required int maxWidth,
    required int quality,
  }) {
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      imageQuality: quality,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  Result<File> _resultFor(XFile? picked) {
    return picked == null
        ? const Err(PermissionFailure('Съёмка отменена'))
        : Ok(File(picked.path));
  }
}
