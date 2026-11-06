import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 8),
  }) : _dio = dio;

  final Dio _dio;
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Random _random = Random();

  static const _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final attempt = (err.requestOptions.extra[_attemptKey] as int? ?? 0) + 1;
    if (attempt >= maxAttempts) {
      handler.next(err);
      return;
    }

    final backoff = baseDelay * pow(2, attempt - 1).toDouble();
    final capped = backoff > maxDelay ? maxDelay : backoff;
    final jitter = Duration(
      milliseconds: _random.nextInt(250),
    );
    await Future<void>.delayed(capped + jitter);

    final options = err.requestOptions..extra[_attemptKey] = attempt;
    final idempotencyKey = options.extra['idempotencyKey'];
    if (idempotencyKey is String) {
      options.headers['Idempotency-Key'] = idempotencyKey;
    }

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.requestOptions.method == 'POST' &&
        err.requestOptions.extra['idempotencyKey'] == null) {
      return false;
    }
    return switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => true,
      DioExceptionType.badResponse =>
        (err.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
