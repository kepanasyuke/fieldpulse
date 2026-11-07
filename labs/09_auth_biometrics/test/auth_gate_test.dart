import 'package:flutter_test/flutter_test.dart';

import 'package:lab_auth_biometrics/src/auth_gate.dart';

void main() {
  group('AuthGate', () {
    test('верный PIN открывает доступ', () {
      final gate = AuthGate(pin: '2468');
      final outcome = gate.submit('2468');

      expect(outcome.isSuccess, isTrue);
      expect(gate.isUnlocked, isTrue);
    });

    test('неверный PIN уменьшает счётчик попыток', () {
      final gate = AuthGate(pin: '2468');
      final outcome = gate.submit('1111');

      expect(outcome.isFailure, isTrue);
      expect(outcome.attemptsLeft, 2);
      expect(gate.isLocked, isFalse);
    });

    test('после исчерпания попыток вход блокируется', () {
      final gate = AuthGate(pin: '2468', maxAttempts: 2);
      gate.submit('1');
      final outcome = gate.submit('2');

      expect(outcome.isLocked, isTrue);
      expect(gate.isLocked, isTrue);
      expect(gate.submit('2468').isSuccess, isFalse);
    });

    test('reset возвращает попытки', () {
      final gate = AuthGate(pin: '2468', maxAttempts: 1);
      gate.submit('9');
      gate.reset();

      expect(gate.attemptsLeft, 1);
      expect(gate.submit('2468').isSuccess, isTrue);
    });

    test('lock закрывает доступ даже при верном PIN', () {
      final gate = AuthGate(pin: '2468');
      gate.lock();

      expect(gate.submit('2468').isFailure, isTrue);
    });
  });

  group('хелперы', () {
    test('подпись подсказывает остаток попыток', () {
      expect(pinHint(3), 'Осталось попыток: 3');
      expect(pinHint(1), 'Осталась 1 попытка');
      expect(pinHint(0), 'Вход заблокирован');
    });

    test('формат PIN — ровно четыре цифры', () {
      expect(isValidPinFormat('2468'), isTrue);
      expect(isValidPinFormat('246'), isFalse);
      expect(isValidPinFormat('24a8'), isFalse);
    });
  });
}
