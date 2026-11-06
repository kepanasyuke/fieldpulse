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
    widget.repository.watchPendingCount().listen((count) {
      if (mounted) {
        setState(() => _pending = count);
      }
    });
  }

  Future<void> _adjust(String itemId, int delta) async {
    await widget.repository.adjust(itemId, delta, online: _online);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Офлайн-склад'),
        actions: [
          Row(
            children: [
              Text(_online ? 'online' : 'offline'),
              Switch(
                value: _online,
                onChanged: (value) => setState(() => _online = value),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pending > 0)
            Material(
              color: scheme.tertiaryContainer,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_off_rounded, size: 18),
                title: Text('$_pending изменений ждут отправки'),
                trailing: TextButton(
                  onPressed: () async {
                    final sent = await widget.repository.flush();
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Отправлено: $sent')),
                    );
                  },
                  child: const Text('Синхронизировать'),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<StockItem>>(
              stream: widget.repository.watchItems(),
              initialData: widget.repository.items(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <StockItem>[];
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          item.isLow ? 'мало на складе' : 'обновлён только что',
                          style: TextStyle(
                            color: item.isLow
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _adjust(item.id, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _adjust(item.id, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
