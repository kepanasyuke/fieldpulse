enum PaymentStatus { draft, processing, succeeded, failed }

class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.description,
    required this.idempotencyKey,
    this.status = PaymentStatus.draft,
    this.attempts = 0,
    this.transactionId,
    this.failureReason,
  });

  final String id;
  final int amountMinor;
  final String currency;
  final String description;
  final String idempotencyKey;
  final PaymentStatus status;
  final int attempts;
  final String? transactionId;
  final String? failureReason;

  bool get isSettled => status == PaymentStatus.succeeded;
  bool get canRetry => status == PaymentStatus.failed;

  String get amountLabel =>
      '${(amountMinor / 100).toStringAsFixed(2)} ${currency.toUpperCase()}';

  PaymentIntent copyWith({
    PaymentStatus? status,
    int? attempts,
    String? transactionId,
    String? failureReason,
  }) => PaymentIntent(
    id: id,
    amountMinor: amountMinor,
    currency: currency,
    description: description,
    idempotencyKey: idempotencyKey,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    transactionId: transactionId ?? this.transactionId,
    failureReason: failureReason ?? this.failureReason,
  );
}

class PaymentReceipt {
  const PaymentReceipt.succeeded(this.transactionId) : failureReason = null;

  const PaymentReceipt.failed(this.failureReason) : transactionId = null;

  final String? transactionId;
  final String? failureReason;

  bool get isSuccess => transactionId != null;
}

abstract interface class PaymentGateway {
  Future<PaymentReceipt> charge(PaymentIntent intent);
}

class PaymentService {
  PaymentService({required PaymentGateway gateway}) : _gateway = gateway;

  final PaymentGateway _gateway;
  final Map<String, PaymentIntent> _intents = {};
  int _sequence = 0;

  List<PaymentIntent> get intents =>
      _intents.values.toList(growable: false).reversed.toList(growable: false);

  PaymentIntent create({
    required int amountMinor,
    required String description,
    String currency = 'rub',
  }) {
    if (amountMinor <= 0) {
      throw ArgumentError.value(
        amountMinor,
        'amountMinor',
        'Сумма должна быть > 0',
      );
    }

    _sequence++;
    final intent = PaymentIntent(
      id: 'pay-$_sequence',
      amountMinor: amountMinor,
      currency: currency,
      description: description,
      idempotencyKey: 'idem-$_sequence-$amountMinor',
    );
    _intents[intent.id] = intent;
    return intent;
  }

  Future<PaymentIntent> pay(String intentId) async {
    final intent = _intents[intentId];
    return intent == null || intent.isSettled
        ? _intents[intentId] ?? _missing(intentId)
        : _charge(intent);
  }

  Future<PaymentIntent> _charge(PaymentIntent intent) async {
    final pending = _store(
      intent.copyWith(
        status: PaymentStatus.processing,
        attempts: intent.attempts + 1,
      ),
    );
    final receipt = await _gateway.charge(pending);
    return _store(_applyReceipt(pending, receipt));
  }

  PaymentIntent _applyReceipt(PaymentIntent intent, PaymentReceipt receipt) {
    return receipt.isSuccess
        ? intent.copyWith(
            status: PaymentStatus.succeeded,
            transactionId: receipt.transactionId,
          )
        : intent.copyWith(
            status: PaymentStatus.failed,
            failureReason: receipt.failureReason ?? 'Платёж отклонён',
          );
  }

  PaymentIntent _store(PaymentIntent intent) {
    _intents[intent.id] = intent;
    return intent;
  }

  PaymentIntent _missing(String intentId) =>
      throw StateError('Платёж $intentId не найден');
}
