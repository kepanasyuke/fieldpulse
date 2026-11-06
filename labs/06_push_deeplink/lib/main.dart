import 'package:flutter/material.dart';

import 'package:lab_push_deeplink/src/notification_router.dart';

const List<Map<String, dynamic>> _samples = [
  {
    'message_id': 'm-1',
    'type': 'order_updated',
    'order_id': 'o-4211',
    'title': 'Наряд обновлён',
  },
  {
    'message_id': 'm-2',
    'type': 'chat_message',
    'order_id': 'o-4211',
    'title': 'Сообщение от диспетчера',
  },
  {'message_id': 'm-3', 'type': 'broadcast', 'title': 'Плановые работы'},
  {'message_id': 'm-1', 'type': 'order_updated', 'order_id': 'o-4211'},
  {'message_id': 'm-4', 'type': 'order_updated'},
];

void main() => runApp(const PushLabApp());

class PushLabApp extends StatelessWidget {
  const PushLabApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lab 06 · Push & deep link',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B57D0)),
    ),
    home: const PushPage(),
  );
}

class PushPage extends StatefulWidget {
  const PushPage({super.key});

  @override
  State<PushPage> createState() => _PushPageState();
}

class _PushPageState extends State<PushPage> {
  final NotificationRouter _router = NotificationRouter();
  final List<String> _log = [];

  void _handle(Map<String, dynamic> data) {
    final payload = PushPayload.fromData(data);
    final link = _router.resolve(payload);
    setState(() {
      _log.insert(
        0,
        link == null ? 'пропущено: ${payload.messageId}' : 'переход: $link',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push и deep links')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final sample in _samples)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text('${sample['type']}'),
                subtitle: Text(
                  '${sample['title'] ?? ''} ${sample['order_id'] ?? ''}',
                ),
                trailing: TextButton(
                  onPressed: () => _handle(sample),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Журнал', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in _log)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(entry),
            ),
        ],
      ),
    );
  }
}
