import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/native/camera_service.dart';
import 'package:fieldpulse/core/utils/result.dart';
import 'package:fieldpulse/features/orders/domain/repositories/order_repository.dart';

class AttachPhoto {
  AttachPhoto({
    required OrderRepository repository,
    required CameraService camera,
  }) : _repository = repository,
       _camera = camera;

  final OrderRepository _repository;
  final CameraService _camera;

  Future<Result<void>> call(String orderId) async {
    final capture = await _camera.capture();
    return capture.fold(
      ok: (file) async {
        final upload = await _repository.attachPhoto(
          orderId: orderId,
          filePath: file.path,
        );
        return upload.fold(
          ok: (_) => const Ok<void>(null),
          err: (failure) => Err<void>(
            failure is PermissionFailure
                ? const ValidationFailure(
                    'Фото обязательно для закрытия наряда',
                  )
                : failure,
          ),
        );
      },
      err: (failure) async => Err<void>(failure),
    );
  }
}
