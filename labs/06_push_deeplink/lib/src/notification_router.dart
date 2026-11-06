enum PushType { orderUpdated, chatMessage, broadcast }

class PushPayload {
  const PushPayload({
    required this.messageId,
    required this.type,
    this.orderId,
    this.title = '',
    this.body = '',
  });

  final String messageId;
  final PushType type;
  final String? orderId;
  final String title;
  final String body;

  factory PushPayload.fromData(Map<String, dynamic> data) => PushPayload(
    messageId: data['message_id']?.toString() ?? '',
    type: _typeOf(data['type']?.toString()),
    orderId: data['order_id']?.toString(),
    title: data['title']?.toString() ?? '',
    body: data['body']?.toString() ?? '',
  );

  static PushType _typeOf(String? raw) => switch (raw) {
    'order_updated' => PushType.orderUpdated,
    'chat_message' => PushType.chatMessage,
    _ => PushType.broadcast,
  };
}

sealed class AppDeepLink {
  const AppDeepLink(this.route);

  final String route;

  @override
  String toString() => route;
}

final class OrderDeepLink extends AppDeepLink {
  const OrderDeepLink(String orderId) : super('/orders/$orderId');
}

final class ChatDeepLink extends AppDeepLink {
  const ChatDeepLink(String orderId) : super('/orders/$orderId/chat');
}

final class FeedDeepLink extends AppDeepLink {
  const FeedDeepLink() : super('/feed');
}

class NotificationRouter {
  NotificationRouter({int historyLimit = 50}) : _historyLimit = historyLimit;

  final int _historyLimit;
  final List<String> _handled = [];

  List<String> get handledIds => List.unmodifiable(_handled);

  AppDeepLink? resolve(PushPayload payload) {
    final link = _linkFor(payload);
    return _shouldHandle(payload) && link != null
        ? _remember(payload, link)
        : null;
  }

  bool _shouldHandle(PushPayload payload) =>
      payload.messageId.isNotEmpty && !_handled.contains(payload.messageId);

  AppDeepLink? _linkFor(PushPayload payload) => switch (payload.type) {
    PushType.orderUpdated =>
      payload.orderId == null ? null : OrderDeepLink(payload.orderId!),
    PushType.chatMessage =>
      payload.orderId == null ? null : ChatDeepLink(payload.orderId!),
    PushType.broadcast => const FeedDeepLink(),
  };

  AppDeepLink _remember(PushPayload payload, AppDeepLink link) {
    _handled.add(payload.messageId);
    if (_handled.length > _historyLimit) {
      _handled.removeAt(0);
    }
    return link;
  }
}
