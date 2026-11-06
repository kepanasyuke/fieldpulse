import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:lab_hive_offline/src/stock_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init((await _dataDir()).path);
  final repository = await StockRepository.open();
  if (repository.items().isEmpty) {
    final now = DateTime.now();
    await repository.seed([
      StockItem(id: 's-1', title: 'Счётчик воды', quantity: 12, updatedAt: now),
      StockItem(
        id: 's-2',
        title: 'Кабель UTP, м',
        quantity: 240,
        updatedAt: now,
      ),
      StockItem(id: 's-3', title: 'Пломба', quantity: 2, updatedAt: now),
    ]);
  }
  runApp(OfflineStockApp(repository: repository));
}

Future<Directory> _dataDir() async {
  final dir = Directory('${Directory.systemTemp.path}/fieldpulse_hive');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

class OfflineStockApp extends StatelessWidget {
  const OfflineStockApp({super.key, required this.repository});

  final StockRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lab 02 · Offline stock',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F9D58)),
    ),
    home: StockPage(repository: repository),
  );
}

class StockPage extends StatefulWidget {
  const StockPage({super.key, required this.repository});

  final StockRepository repository;

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  bool _online = true;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    widget.repository.watchPendingCount().listen(_onPendingChanged);
  }

  void _onPendingChanged(int count) {
    if (mounted) {
      setState(() => _pending = count);
    }
  }

  void _toggleOnline(bool value) => setState(() => _online = value);

  Future<void> _adjust(String itemId, int delta) async {
    await widget.repository.adjust(itemId, delta, online: _online);
  }

  Future<void> _flush() async {
    final sent = await widget.repository.flush();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Отправлено: $sent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Офлайн-склад'),
      actions: [_OnlineSwitch(online: _online, onChanged: _toggleOnline)],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _PendingBanner(count: _pending, onFlush: _flush),
        Expanded(
          child: _StockList(repository: widget.repository, onAdjust: _adjust),
        ),
      ],
    );
  }
}

class _OnlineSwitch extends StatelessWidget {
  const _OnlineSwitch({required this.online, required this.onChanged});

  final bool online;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(online ? 'online' : 'offline'),
        Switch(value: online, onChanged: onChanged),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count, required this.onFlush});

  final int count;
  final Future<void> Function() onFlush;

  @override
  Widget build(BuildContext context) {
    return count > 0 ? _buildBanner(context) : const SizedBox.shrink();
  }

  Widget _buildBanner(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.cloud_off_rounded, size: 18),
        title: Text('$count изменений ждут отправки'),
        trailing: TextButton(
          onPressed: onFlush,
          child: const Text('Синхронизировать'),
        ),
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  const _StockList({required this.repository, required this.onAdjust});

  final StockRepository repository;
  final Future<void> Function(String itemId, int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockItem>>(
      stream: repository.watchItems(),
      initialData: repository.items(),
      builder: _buildList,
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncSnapshot<List<StockItem>> snapshot,
  ) {
    final items = snapshot.data ?? const <StockItem>[];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _StockTile(item: items[index], onAdjust: onAdjust),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.item, required this.onAdjust});

  final StockItem item;
  final Future<void> Function(String itemId, int delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.title),
        subtitle: Text(
          _subtitle,
          style: TextStyle(color: _subtitleColor(context)),
        ),
        trailing: _QuantityStepper(
          quantity: item.quantity,
          onMinus: () => onAdjust(item.id, -1),
          onPlus: () => onAdjust(item.id, 1),
        ),
      ),
    );
  }

  String get _subtitle => item.isLow ? 'мало на складе' : 'обновлён только что';

  Color _subtitleColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return item.isLow ? scheme.error : scheme.onSurfaceVariant;
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
