import 'package:flutter/material.dart';

import 'package:lab_realtime_chat/src/chat_client.dart';

void main() => runApp(const RealtimeChatApp());

class RealtimeChatApp extends StatelessWidget {
  const RealtimeChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 01 · Realtime chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C4CF1)),
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatClient _client = ChatClient(url: 'wss://ws.postman-echo.com/raw');
  final TextEditingController _input = TextEditingController();
  final List<ChatMessage> _history = [];
  ChatConnection _connection = ChatConnection.idle;

  @override
  void initState() {
    super.initState();
    _client.connection.listen((status) {
      if (mounted) {
        setState(() => _connection = status);
      }
    });
    _client.messages.listen((message) {
      if (mounted) {
        setState(() => _history.add(message));
      }
    });
    _client.connect();
  }

  @override
  void dispose() {
    _input.dispose();
    _client.dispose();
    super.dispose();
  }

  Color _statusColor(ColorScheme scheme) => switch (_connection) {
    ChatConnection.online => scheme.primary,
    ChatConnection.connecting => scheme.tertiary,
    ChatConnection.offline => scheme.error,
    ChatConnection.idle => scheme.outline,
  };

  String _statusLabel() => switch (_connection) {
    ChatConnection.online => 'На связи',
    ChatConnection.connecting => 'Подключаемся…',
    ChatConnection.offline => 'Нет связи, переподключаемся',
    ChatConnection.idle => 'Ожидание',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: _statusColor(scheme)),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final message = _history[index];
                final mine = message.author == 'me';
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: mine
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(hintText: 'Сообщение'),
                      onSubmitted: (value) {
                        _client.send(value);
                        _input.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      _client.send(_input.text);
                      _input.clear();
                    },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
