import 'package:local_auth/local_auth.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/utils/result.dart';

class BiometricService {
  BiometricService(this._auth);

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on Exception catch (_) {
      return false;
    }
  }

  Future<Result<void>> authenticate({
    String reason = 'Подтвердите личность для доступа к заказам',
  }) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );
      return success
          ? const Ok<void>(null)
          : const Err<void>(PermissionFailure('Биометрия не подтверждена'));
    } on Exception catch (error) {
      return Err<void>(PermissionFailure('Биометрия недоступна: $error'));
    }
  }
}
