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
      theme: _theme(),
      home: const ChatPage(),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C4CF1)),
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
    _client.connection.listen(_onConnection);
    _client.messages.listen(_onMessage);
    _client.connect();
  }

  @override
  void dispose() {
    _input.dispose();
    _client.dispose();
    super.dispose();
  }

  void _onConnection(ChatConnection status) {
    if (mounted) {
      setState(() => _connection = status);
    }
  }

  void _onMessage(ChatMessage message) {
    if (mounted) {
      setState(() => _history.add(message));
    }
  }

  void _send(String text) {
    _client.send(text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime chat'),
        actions: [_ConnectionBadge(status: _connection)],
      ),
      body: _ChatBody(history: _history, input: _input, onSend: _send),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status});

  final ChatConnection status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _badgeRow(context),
    );
  }

  Widget _badgeRow(BuildContext context) {
    return Row(children: _items(context));
  }

  List<Widget> _items(BuildContext context) {
    final theme = Theme.of(context);

    return [
      Icon(Icons.circle, size: 10, color: _color(theme.colorScheme)),
      const SizedBox(width: 6),
      Text(_label(), style: theme.textTheme.bodySmall),
    ];
  }

  Color _color(ColorScheme scheme) {
    return switch (status) {
      ChatConnection.online => scheme.primary,
      ChatConnection.connecting => scheme.tertiary,
      ChatConnection.offline => scheme.error,
      ChatConnection.idle => scheme.outline,
    };
  }

  String _label() {
    return switch (status) {
      ChatConnection.online => 'На связи',
      ChatConnection.connecting => 'Подключаемся…',
      ChatConnection.offline => 'Нет связи, переподключаемся',
      ChatConnection.idle => 'Ожидание',
    };
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.history,
    required this.input,
    required this.onSend,
  });

  final List<ChatMessage> history;
  final TextEditingController input;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _MessageList(history: history)),
        _Composer(input: input, onSend: onSend),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.history});

  final List<ChatMessage> history;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) => _MessageBubble(message: history[index]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(alignment: _alignment(), child: _bubble(context));
  }

  Alignment _alignment() {
    return message.author == 'me'
        ? Alignment.centerRight
        : Alignment.centerLeft;
  }

  Widget _bubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: _decoration(context),
      child: Text(message.text),
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMine = message.author == 'me';

    return BoxDecoration(
      color: isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.input, required this.onSend});

  final TextEditingController input;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(padding: const EdgeInsets.all(12), child: _row()),
    );
  }

  Widget _row() {
    return Row(children: _items());
  }

  List<Widget> _items() {
    return [
      Expanded(
        child: _InputField(controller: input, onSend: onSend),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        onPressed: () => onSend(input.text),
        icon: const Icon(Icons.send_rounded),
      ),
    ];
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.controller, required this.onSend});

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(hintText: 'Сообщение'),
      onSubmitted: onSend,
    );
  }
}
