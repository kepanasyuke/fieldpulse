import 'package:flutter/material.dart';

import 'package:lab_payments/src/payment_service.dart';

class FakeGateway implements PaymentGateway {
  FakeGateway({this.failuresBeforeSuccess = 0});

  int failuresBeforeSuccess;
  final List<String> receivedKeys = [];

  @override
  Future<PaymentReceipt> charge(PaymentIntent intent) async {
    receivedKeys.add(intent.idempotencyKey);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      return const PaymentReceipt.failed('Банк отклонил операцию');
    }
    return PaymentReceipt.succeeded('tx-${intent.idempotencyKey}');
  }
}

void main() => runApp(const PaymentsApp());

class PaymentsApp extends StatelessWidget {
  const PaymentsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lab 05 · Payments',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
    ),
    home: const PaymentsPage(),
  );
}

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final PaymentService _service = PaymentService(
    gateway: FakeGateway(failuresBeforeSuccess: 1),
  );

  @override
  void initState() {
    super.initState();
    _service
      ..create(amountMinor: 129000, description: 'Абонемент, ноябрь')
      ..create(amountMinor: 45000, description: 'Выезд инженера');
  }

  Future<void> _pay(PaymentIntent intent) async {
    await _service.pay(intent.id);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Платежи')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final intent in _service.intents)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(intent.description),
                subtitle: Text(
                  '${intent.amountLabel} · ${_statusLabel(intent)}'
                  '${intent.attempts > 1 ? ' · попыток: ${intent.attempts}' : ''}',
                ),
                trailing: _actionButton(intent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(PaymentIntent intent) {
    switch (intent.status) {
      case PaymentStatus.succeeded:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case PaymentStatus.processing:
        return const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        );
      case PaymentStatus.draft:
      case PaymentStatus.failed:
        return FilledButton(
          onPressed: () => _pay(intent),
          child: Text(intent.canRetry ? 'Повторить' : 'Оплатить'),
        );
    }
  }

  String _statusLabel(PaymentIntent intent) => switch (intent.status) {
    PaymentStatus.draft => 'черновик',
    PaymentStatus.processing => 'обрабатывается',
    PaymentStatus.succeeded => 'оплачен',
    PaymentStatus.failed => intent.failureReason ?? 'ошибка',
  };
}
