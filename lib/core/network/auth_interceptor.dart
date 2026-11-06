import 'package:dio/dio.dart';

import 'package:core_storage/core_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required SecureTokenStore tokenStore,
    required Future<void> Function() onUnauthorized,
  }) : _tokenStore = tokenStore,
       _onUnauthorized = onUnauthorized;

  final SecureTokenStore _tokenStore;
  final Future<void> Function() _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokenStore.clearTokens();
      await _onUnauthorized();
    }
    handler.next(err);
  }
}
