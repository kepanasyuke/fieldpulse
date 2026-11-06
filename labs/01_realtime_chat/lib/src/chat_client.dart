import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum ChatConnection { idle, connecting, online, offline }

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.text,
    required this.sentAt,
  });

  final String author;
  final String text;
  final DateTime sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    author: json['author'] as String? ?? 'guest',
    text: json['text'] as String? ?? '',
    sentAt:
        DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'author': author,
    'text': text,
    'sent_at': sentAt.toUtc().toIso8601String(),
  };
}

typedef ChatSocketFactory = WebSocketChannel Function(Uri uri);

class ChatClient {
  ChatClient({
    required this.url,
    ChatSocketFactory? socketFactory,
    this.reconnectDelay = const Duration(seconds: 2),
  }) : _socketFactory = socketFactory ?? WebSocketChannel.connect;

  final String url;
  final Duration reconnectDelay;
  final ChatSocketFactory _socketFactory;

  final StreamController<ChatMessage> _messages =
      StreamController<ChatMessage>.broadcast();
  final StreamController<ChatConnection> _connection =
      StreamController<ChatConnection>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _closed = false;
  ChatConnection _status = ChatConnection.idle;

  Stream<ChatMessage> get messages => _messages.stream;

  Stream<ChatConnection> get connection => _connection.stream;

  ChatConnection get status => _status;

  Future<void> connect() async {
    if (_closed ||
        _status == ChatConnection.online ||
        _status == ChatConnection.connecting) {
      return;
    }
    _emit(ChatConnection.connecting);

    try {
      final channel = _socketFactory(Uri.parse(url));
      _channel = channel;
      await channel.ready;
      await _subscription?.cancel();
      _subscription = channel.stream.listen(
        _handleFrame,
        onError: (Object error) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: false,
      );
      _emit(ChatConnection.online);
    } on Object {
      _scheduleReconnect();
    }
  }

  void _handleFrame(Object? frame) {
    if (frame is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(frame);
      if (decoded is Map<String, dynamic> && !_messages.isClosed) {
        _messages.add(ChatMessage.fromJson(decoded));
      }
    } on FormatException {
      return;
    }
  }

  void _scheduleReconnect() {
    if (_closed) {
      return;
    }
    _emit(ChatConnection.offline);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      unawaited(_closeChannel());
      unawaited(connect());
    });
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _channel == null) {
      return;
    }
    _channel!.sink.add(
      jsonEncode(
        ChatMessage(
          author: 'me',
          text: trimmed,
          sentAt: DateTime.now(),
        ).toJson(),
      ),
    );
  }

  void _emit(ChatConnection status) {
    _status = status;
    if (!_connection.isClosed) {
      _connection.add(status);
    }
  }

  Future<void> _closeChannel() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _closeChannel();
    _emit(ChatConnection.idle);
    await _messages.close();
    await _connection.close();
  }
}
