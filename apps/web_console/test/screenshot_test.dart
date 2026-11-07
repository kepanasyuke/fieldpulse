@Tags(['golden'])
library;

import 'dart:io';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_console/src/console_data.dart';
import 'package:web_console/src/ui/console_shell.dart';

Future<void> _loadRealFont() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    return;
  }

  final file = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  if (!file.existsSync()) {
    return;
  }

  final bytes = await file.readAsBytes();
  final loader = FontLoader('Roboto')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Widget _console({String? filter}) {
  final orders = demoOrders();

  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: ConsoleShell(
      metrics: ConsoleMetrics.of(orders),
      filter: filter,
      options: statusOptions(orders),
      orders: sortBySla(filterByStatus(orders, filter)),
      onFilterSelected: (_) {},
    ),
  );
}

Future<void> _shot(
  WidgetTester tester, {
  required Size size,
  String? filter,
  required String golden,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_console(filter: filter));
  await tester.pumpAndSettle();

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$golden'),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadRealFont();
  });

  testWidgets('кадр 1: все наряды', (tester) async {
    await _shot(
      tester,
      size: const Size(1440, 900),
      golden: 'console-frame-1.png',
    );
  });

  testWidgets('кадр 2: фильтр «в работе»', (tester) async {
    await _shot(
      tester,
      size: const Size(1440, 900),
      filter: 'в работе',
      golden: 'console-frame-2.png',
    );
  });

  testWidgets('кадр 3: фильтр «назначен»', (tester) async {
    await _shot(
      tester,
      size: const Size(1440, 900),
      filter: 'назначен',
      golden: 'console-frame-3.png',
    );
  });

  testWidgets('планшетная ширина', (tester) async {
    await _shot(
      tester,
      size: const Size(820, 1180),
      golden: 'console-tablet.png',
    );
  });
}
