import 'package:dio/dio.dart';

import 'package:core_network/core_network.dart';

extension DioFailureMapper on Object {
  Failure toFailure() => switch (this) {
    final Failure failure => failure,
    final DioException exception => _mapDioException(exception),
    _ => UnknownFailure(toString()),
  };
}

Failure _mapDioException(DioException exception) => switch (exception.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout => const TimeoutFailure(),
  DioExceptionType.connectionError => const NetworkFailure(),
  DioExceptionType.badCertificate => const NetworkFailure(
    'Недействительный сертификат сервера',
  ),
  DioExceptionType.cancel => const UnknownFailure('Запрос отменён'),
  DioExceptionType.badResponse => _mapStatus(exception.response),
  DioExceptionType.unknown => const NetworkFailure(),
};

Failure _mapStatus(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final message = _serverMessage(response?.data);

  if (status == 401 || status == 403) {
    return UnauthorizedFailure(message ?? 'Сессия истекла, войдите заново');
  }
  if (status == 422 && response?.data is Map<String, dynamic>) {
    return ValidationFailure(
      message ?? 'Проверьте введённые данные',
      fieldErrors: _fieldErrors(response?.data),
    );
  }
  if (status >= 500) {
    return ServerFailure(status, message ?? 'Сервис временно недоступен');
  }
  return ServerFailure(status, message ?? 'Ошибка запроса ($status)');
}

String? _serverMessage(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  }
  return null;
}

Map<String, String> _fieldErrors(Object? data) {
  if (data is! Map<String, dynamic>) {
    return const {};
  }
  final errors = data['errors'];
  if (errors is! Map) {
    return const {};
  }
  return errors.map((key, value) => MapEntry(key.toString(), value.toString()));
}
