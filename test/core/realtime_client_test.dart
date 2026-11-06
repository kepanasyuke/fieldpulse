import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpulse/core/realtime/realtime_client.dart';

void main() {
  group('RealtimeClient', () {
    test('подставляет токен в query-параметры и уходит в реконнект', () async {
      Uri? requested;
      final client = RealtimeClient(
        url: 'wss://api.fieldpulse.dev/realtime?client=flutter',
        tokenProvider: () async => 'token-123',
        channelFactory: (uri) {
          requested = uri;
          throw StateError('network unreachable');
        },
      );

      final statuses = <RealtimeStatus>[];
      final subscription = client.statuses.listen(statuses.add);

      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(requested, isNotNull);
      expect(requested!.queryParameters['token'], 'token-123');
      expect(requested!.queryParameters['client'], 'flutter');
      expect(statuses, [
        RealtimeStatus.connecting,
        RealtimeStatus.reconnecting,
      ]);
      expect(client.status, RealtimeStatus.reconnecting);

      await subscription.cancel();
      await client.dispose();
    });

    test('повторный connect не открывает второе соединение', () async {
      var calls = 0;
      final client = RealtimeClient(
        url: 'wss://api.fieldpulse.dev/realtime',
        tokenProvider: () async => '',
        channelFactory: (uri) {
          calls++;
          throw StateError('offline');
        },
      );

      await client.connect();
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(calls, 1);

      await client.dispose();
    });

    test('после dispose статус disconnected и стримы закрыты', () async {
      final client = RealtimeClient(
        url: 'wss://api.fieldpulse.dev/realtime',
        tokenProvider: () async => null,
        channelFactory: (uri) => throw StateError('offline'),
      );

      final framesDone = client.frames.toList();
      await client.connect();
      await client.dispose();

      expect(client.status, RealtimeStatus.disconnected);
      expect(await framesDone, isEmpty);
    });
  });
}
