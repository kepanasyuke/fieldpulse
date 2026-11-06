import 'dart:async';

import 'package:dio/dio.dart';

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
  const UnauthorizedFailure([super.message = 'Требуется авторизация']);
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

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Err<T>(:final failure) => failure,
    Ok<T>() => null,
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  Future<Result<R>> asyncMap<R>(Future<R> Function(T value) transform) async =>
      switch (this) {
        Ok<T>(:final value) => Ok<R>(await transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };

  R fold<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

extension DioFailureMapper on Object {
  Failure toFailure() => switch (this) {
    final Failure failure => failure,
    final DioException exception => _mapDio(exception),
    _ => UnknownFailure(toString()),
  };
}

Failure _mapDio(DioException exception) => switch (exception.type) {
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
    return UnauthorizedFailure(message ?? 'Требуется авторизация');
  }
  if (status == 422) {
    return ValidationFailure(message ?? 'Проверьте введённые данные');
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

class ApiClient {
  ApiClient({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 15),
    List<Interceptor> interceptors = const [],
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: timeout,
           receiveTimeout: timeout,
           sendTimeout: timeout,
           headers: const {'Accept': 'application/json'},
         ),
       ) {
    dio.interceptors.addAll(interceptors);
  }

  final Dio dio;

  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error) {
      return Err(error.toFailure());
    }
  }

  void dispose() => dio.close(force: true);
}

Future<void> retry<T>(
  Future<T> Function() action, {
  int attempts = 3,
  Duration baseDelay = const Duration(milliseconds: 300),
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      await action();
      return;
    } on Object catch (error) {
      lastError = error;
      if (attempt == attempts) {
        break;
      }
      await Future<void>.delayed(baseDelay * attempt);
    }
  }
  if (lastError != null) {
    throw lastError;
  }
}
