import 'package:flutter_test/flutter_test.dart';

import 'package:lab_payments/src/payment_service.dart';

class _ScriptedGateway implements PaymentGateway {
  _ScriptedGateway(this.receipts);

  final List<PaymentReceipt> receipts;
  final List<String> keys = [];

  @override
  Future<PaymentReceipt> charge(PaymentIntent intent) async {
    keys.add(intent.idempotencyKey);
    return receipts.removeAt(0);
  }
}

void main() {
  group('PaymentService', () {
    test('создаёт платёж с неизменным ключом идемпотентности', () {
      final service = PaymentService(gateway: _ScriptedGateway(const []));
      final intent = service.create(amountMinor: 150000, description: 'Выезд');

      expect(intent.idempotencyKey, isNotEmpty);
      expect(intent.amountLabel, '1500.00 RUB');
      expect(intent.status, PaymentStatus.draft);
    });

    test('отклоняет нулевую и отрицательную сумму', () {
      final service = PaymentService(gateway: _ScriptedGateway(const []));

      expect(
        () => service.create(amountMinor: 0, description: 'Пусто'),
        throwsArgumentError,
      );
    });

    test('успешная оплата переводит платёж в succeeded', () async {
      final gateway = _ScriptedGateway([
        const PaymentReceipt.succeeded('tx-1'),
      ]);
      final service = PaymentService(gateway: gateway);
      final intent = service.create(amountMinor: 1000, description: 'Тест');

      final result = await service.pay(intent.id);

      expect(result.status, PaymentStatus.succeeded);
      expect(result.transactionId, 'tx-1');
      expect(result.attempts, 1);
    });

    test('после ошибки повтор идёт с тем же ключом идемпотентности', () async {
      final gateway = _ScriptedGateway([
        const PaymentReceipt.failed('Нет средств'),
        const PaymentReceipt.succeeded('tx-2'),
      ]);
      final service = PaymentService(gateway: gateway);
      final intent = service.create(amountMinor: 5000, description: 'Тест');

      final failed = await service.pay(intent.id);
      final retried = await service.pay(intent.id);

      expect(failed.status, PaymentStatus.failed);
      expect(failed.failureReason, 'Нет средств');
      expect(retried.status, PaymentStatus.succeeded);
      expect(gateway.keys.toSet(), hasLength(1));
      expect(retried.attempts, 2);
    });

    test('успешный платёж повторно не отправляется в шлюз', () async {
      final gateway = _ScriptedGateway([
        const PaymentReceipt.succeeded('tx-3'),
      ]);
      final service = PaymentService(gateway: gateway);
      final intent = service.create(amountMinor: 7000, description: 'Тест');

      await service.pay(intent.id);
      final second = await service.pay(intent.id);

      expect(second.status, PaymentStatus.succeeded);
      expect(gateway.keys, hasLength(1));
    });

    test('неизвестный платёж даёт понятную ошибку', () async {
      final service = PaymentService(gateway: _ScriptedGateway(const []));

      expect(service.pay('pay-404'), throwsStateError);
    });
  });
}
