class AuthOutcome {
  const AuthOutcome({
    required this.isSuccess,
    required this.attemptsLeft,
    required this.isLocked,
    this.message,
  });

  final bool isSuccess;
  final int attemptsLeft;
  final bool isLocked;
  final String? message;

  bool get isFailure => !isSuccess;
}

class AuthGate {
  AuthGate({required this.pin, this.maxAttempts = 3})
    : _attemptsLeft = maxAttempts;

  final String pin;
  final int maxAttempts;

  int _attemptsLeft;
  bool _unlocked = false;

  int get attemptsLeft => _attemptsLeft;

  bool get isLocked => _attemptsLeft <= 0;

  bool get isUnlocked => _unlocked;

  AuthOutcome submit(String candidate) {
    if (isLocked) {
      return _failure('Попытки исчерпаны, обратитесь в поддержку');
    }
    if (candidate == pin) {
      _unlocked = true;

      return const AuthOutcome(
        isSuccess: true,
        attemptsLeft: 0,
        isLocked: false,
      );
    }

    _attemptsLeft = _attemptsLeft > 0 ? _attemptsLeft - 1 : 0;

    return _failure(
      _attemptsLeft == 0 ? 'Доступ заблокирован' : 'Неверный PIN',
    );
  }

  void lock() {
    _attemptsLeft = 0;
    _unlocked = false;
  }

  void reset() {
    _attemptsLeft = maxAttempts;
    _unlocked = false;
  }

  AuthOutcome _failure(String message) {
    return AuthOutcome(
      isSuccess: false,
      attemptsLeft: _attemptsLeft,
      isLocked: isLocked,
      message: message,
    );
  }
}

String pinHint(int attemptsLeft) {
  return switch (attemptsLeft) {
    0 => 'Вход заблокирован',
    1 => 'Осталась 1 попытка',
    _ => 'Осталось попыток: $attemptsLeft',
  };
}

bool isValidPinFormat(String value) {
  final digitsOnly = RegExp(r'^\d{4}$');

  return digitsOnly.hasMatch(value);
}
