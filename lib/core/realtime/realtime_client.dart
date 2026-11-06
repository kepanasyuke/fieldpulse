import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef RealtimeFrame = Map<String, dynamic>;
typedef WebSocketFactory = WebSocketChannel Function(Uri uri);

enum RealtimeStatus { idle, connecting, connected, reconnecting, disconnected }

class RealtimeClient {
  RealtimeClient({
    required this.url,
    required Future<String?> Function() tokenProvider,
    WebSocketFactory? channelFactory,
    this.heartbeatInterval = const Duration(seconds: 25),
    this.baseBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
  }) : _tokenProvider = tokenProvider,
       _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final String url;
  final Duration heartbeatInterval;
  final Duration baseBackoff;
  final Duration maxBackoff;

  final Future<String?> Function() _tokenProvider;
  final WebSocketFactory _channelFactory;
  final Random _random = Random();

  final StreamController<RealtimeFrame> _frames =
      StreamController<RealtimeFrame>.broadcast();
  final StreamController<RealtimeStatus> _statuses =
      StreamController<RealtimeStatus>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _closed = false;
  RealtimeStatus _status = RealtimeStatus.idle;

  Stream<RealtimeFrame> get frames => _frames.stream;

  Stream<RealtimeStatus> get statuses => _statuses.stream;

  RealtimeStatus get status => _status;

  Future<void> connect() async {
    if (_closed ||
        _status == RealtimeStatus.connected ||
        _status == RealtimeStatus.connecting ||
        _status == RealtimeStatus.reconnecting) {
      return;
    }
    _attempt = 0;
    await _open();
  }

  Future<void> _open() async {
    if (_closed || _status == RealtimeStatus.connected) {
      return;
    }
    _setStatus(
      _attempt == 0 ? RealtimeStatus.connecting : RealtimeStatus.reconnecting,
    );

    try {
      final uri = await _connectUri();

      final channel = _channelFactory(uri);
      _channel = channel;
      await channel.ready;

      await _subscription?.cancel();
      _subscription = channel.stream.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _attempt = 0;
      _setStatus(RealtimeStatus.connected);
      _startHeartbeat();
    } on Object catch (error) {
      debugPrint('Realtime handshake failed: $error');
      _scheduleReconnect();
    }
  }

  Future<Uri> _connectUri() async {
    final token = await _tokenProvider();
    final base = Uri.parse(url);
    final params = _withToken(base.queryParameters, token);

    return base.replace(queryParameters: params);
  }

  Map<String, String> _withToken(Map<String, String> params, String? token) {
    if (token == null || token.isEmpty) {
      return params;
    }

    return {...params, 'token': token};
  }

  void _handleData(Object? data) {
    if (data is String) {
      _decode(data);
    }
  }

  void _decode(String raw) {
    try {
      _emitFrame(jsonDecode(raw));
    } on FormatException catch (error) {
      debugPrint('Realtime payload is not JSON: $error');
    }
  }

  void _emitFrame(Object? decoded) {
    final isFrame = decoded is Map<String, dynamic>;
    final isPong = isFrame && decoded['type'] == 'pong';

    if (isFrame && !isPong && !_frames.isClosed) {
      _frames.add(decoded);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    debugPrint('Realtime error: $error');
    _scheduleReconnect();
  }

  void _handleDone() {
    _heartbeat?.cancel();
    if (!_closed) {
      _scheduleReconnect();
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(heartbeatInterval, (_) => _sendPing());
  }

  void _sendPing() {
    _channel?.sink.add(jsonEncode(_pingPayload()));
  }

  Map<String, dynamic> _pingPayload() {
    return {'type': 'ping', 'ts': DateTime.now().toUtc().toIso8601String()};
  }

  void _scheduleReconnect() {
    if (_closed) {
      return;
    }
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _setStatus(RealtimeStatus.reconnecting);

    final exponential = baseBackoff * pow(2, min(_attempt, 5)).toDouble();
    final capped = exponential > maxBackoff ? maxBackoff : exponential;
    final delay = capped + Duration(milliseconds: _random.nextInt(400));
    _attempt++;

    _reconnectTimer = Timer(delay, () {
      unawaited(_disposeChannel());
      unawaited(_open());
    });
  }

  void _setStatus(RealtimeStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    if (!_statuses.isClosed) {
      _statuses.add(status);
    }
  }

  Future<void> _disposeChannel() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> disconnect() async {
    _closed = true;
    _reconnectTimer?.cancel();
    _heartbeat?.cancel();
    await _disposeChannel();
    _setStatus(RealtimeStatus.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _frames.close();
    await _statuses.close();
  }
}
