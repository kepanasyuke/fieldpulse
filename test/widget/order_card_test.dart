import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:fieldpulse/app/theme/app_theme.dart';
import 'package:fieldpulse/features/orders/domain/entities/order.dart';
import 'package:fieldpulse/features/orders/presentation/widgets/order_card.dart';

Order buildOrder({
  OrderStatus status = OrderStatus.assigned,
  OrderPriority priority = OrderPriority.normal,
  int photos = 0,
  bool pending = false,
}) => Order(
  id: 'o-1',
  number: 'FP-1042',
  title: 'Замена счётчика',
  customer: 'ООО «Ромашка»',
  address: 'Москва, Ленинский пр-т, 42',
  status: status,
  priority: priority,
  updatedAt: DateTime.utc(2026, 11, 6, 9),
  photos: List<OrderPhoto>.generate(
    photos,
    (index) => OrderPhoto(
      id: 'p-$index',
      url: 'https://cdn.fieldpulse.dev/p-$index.jpg',
      capturedAt: DateTime.utc(2026, 11, 6, 9),
    ),
  ),
  hasPendingUpdate: pending,
);

Future<void> pumpCard(WidgetTester tester, Order order) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: OrderCard(order: order, onTap: () {}),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets('карточка показывает номер, заголовок, адрес и статус', (
    tester,
  ) async {
    await pumpCard(tester, buildOrder());

    expect(find.text('FP-1042'), findsOneWidget);
    expect(find.text('Замена счётчика'), findsOneWidget);
    expect(find.text('Москва, Ленинский пр-т, 42'), findsOneWidget);
    expect(find.text('Назначен'), findsOneWidget);
  });

  testWidgets('срочный приоритет подсвечивается', (tester) async {
    await pumpCard(tester, buildOrder(priority: OrderPriority.critical));

    expect(find.text('Критичный'), findsOneWidget);
  });

  testWidgets('показывает счётчик фото и иконку неотправленных изменений', (
    tester,
  ) async {
    await pumpCard(tester, buildOrder(photos: 2, pending: true));

    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('тап по карточке вызывает колбэк', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: OrderCard(order: buildOrder(), onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.byType(OrderCard));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
