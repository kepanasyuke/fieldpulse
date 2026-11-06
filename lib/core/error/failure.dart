sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет соединения с сервером']);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Сервер не ответил вовремя']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Сессия истекла, войдите заново']);
}

final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, [String message = 'Ошибка сервера'])
    : super(message);

  final int statusCode;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Локальный кэш недоступен']);
}

final class GeolocationFailure extends Failure {
  const GeolocationFailure([
    super.message = 'Не удалось определить местоположение',
  ]);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Разрешение не выдано']);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Непредвиденная ошибка']);
}
