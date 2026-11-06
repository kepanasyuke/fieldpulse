import 'package:flutter_test/flutter_test.dart';

import 'package:lab_realtime_chat/src/chat_client.dart';

void main() {
  group('ChatMessage', () {
    test('читает кадр чата', () {
      final message = ChatMessage.fromJson({
        'author': 'диспетчер',
        'text': 'Наряд принят',
        'sent_at': '2026-11-06T10:15:00Z',
      });

      expect(message.author, 'диспетчер');
      expect(message.text, 'Наряд принят');
      expect(message.sentAt.isUtc, isTrue);
    });

    test('не падает на неполном кадре', () {
      final message = ChatMessage.fromJson({'text': 42});

      expect(message.author, 'guest');
      expect(message.text, '');
    });
  });

  group('ChatClient', () {
    test('уходит в offline при сбое подключения', () async {
      final client = ChatClient(
        url: 'wss://example.dev/chat',
        socketFactory: (uri) => throw StateError('offline'),
      );

      final statuses = <ChatConnection>[];
      final subscription = client.connection.listen(statuses.add);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(statuses, [ChatConnection.connecting, ChatConnection.offline]);
      expect(client.status, ChatConnection.offline);

      await subscription.cancel();
      await client.dispose();
    });

    test('повторный connect не открывает второе соединение', () async {
      var calls = 0;
      final client = ChatClient(
        url: 'wss://example.dev/chat',
        socketFactory: (uri) {
          calls++;
          throw StateError('offline');
        },
      );

      await client.connect();
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(calls, 2);

      await client.dispose();
    });

    test('отправка без соединения не бросает исключение', () async {
      final client = ChatClient(
        url: 'wss://example.dev/chat',
        socketFactory: (uri) => throw StateError('offline'),
      );

      await client.send('привет');
      await client.connect();
      await client.send('ещё раз');
      await client.dispose();

      expect(client.status, ChatConnection.idle);
    });
  });
}
