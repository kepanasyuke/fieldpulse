import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/utils/result.dart';

class CameraService {
  CameraService(this._picker);

  final ImagePicker _picker;

  Future<Result<File>> capture({
    ImageSource source = ImageSource.camera,
    int maxWidth = 1920,
    int quality = 85,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        imageQuality: quality,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) {
        return const Err(PermissionFailure('Съёмка отменена'));
      }
      return Ok(File(picked.path));
    } on Exception catch (error) {
      return Err(PermissionFailure('Камера недоступна: $error'));
    }
  }
}
