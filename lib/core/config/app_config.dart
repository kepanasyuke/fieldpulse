class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.realtimeUrl,
    this.requestTimeout = const Duration(seconds: 15),
    this.cacheTtl = const Duration(minutes: 10),
    this.enableNetworkLogs = false,
  });

  final String apiBaseUrl;
  final String realtimeUrl;
  final Duration requestTimeout;
  final Duration cacheTtl;
  final bool enableNetworkLogs;

  static const AppConfig fromEnvironment = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.fieldpulse.dev/v1',
    ),
    realtimeUrl: String.fromEnvironment(
      'WS_URL',
      defaultValue: 'wss://api.fieldpulse.dev/realtime',
    ),
    enableNetworkLogs: bool.fromEnvironment('NETWORK_LOGS'),
  );

  AppConfig copyWith({bool? enableNetworkLogs}) => AppConfig(
    apiBaseUrl: apiBaseUrl,
    realtimeUrl: realtimeUrl,
    requestTimeout: requestTimeout,
    cacheTtl: cacheTtl,
    enableNetworkLogs: enableNetworkLogs ?? this.enableNetworkLogs,
  );
}
