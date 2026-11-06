import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:fieldpulse/core/config/app_config.dart';
import 'package:fieldpulse/core/network/auth_interceptor.dart';
import 'package:fieldpulse/core/network/retry_interceptor.dart';
import 'package:fieldpulse/core/storage/secure_token_store.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required SecureTokenStore tokenStore,
    required Future<void> Function() onUnauthorized,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: config.requestTimeout,
           receiveTimeout: config.requestTimeout,
           sendTimeout: config.requestTimeout,
           headers: const {
             'Accept': 'application/json',
             'X-Client-Version': 'fieldpulse/1.0.0',
           },
           responseType: ResponseType.json,
         ),
       ) {
    dio.interceptors.addAll([
      AuthInterceptor(tokenStore: tokenStore, onUnauthorized: onUnauthorized),
      RetryInterceptor(dio: dio),
      if (config.enableNetworkLogs)
        PrettyDioLogger(
          requestBody: true,
          responseBody: true,
          compact: true,
          maxWidth: 120,
        ),
    ]);
  }

  final Dio dio;

  Future<Response<T>> getJson<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) => dio.get<T>(
    path,
    queryParameters: queryParameters,
    cancelToken: cancelToken,
    options: Options(responseType: ResponseType.plain),
  );

  void dispose() => dio.close(force: true);
}
