import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_network/core_network.dart';
import 'package:fieldpulse/core/native/biometric_service.dart';
import 'package:core_storage/core_storage.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';
import 'package:fieldpulse/features/auth/domain/entities/auth_user.dart';
import 'package:fieldpulse/features/auth/presentation/bloc/app_lock_bloc.dart';

class _MockBiometricService extends Mock implements BiometricService {}

class _MockSettingsStore extends Mock implements SettingsStore {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockBiometricService biometrics;
  late _MockSettingsStore settings;
  late _MockAuthRepository auth;

  const user = AuthUser(uid: 'engineer-1', email: 'engineer@fieldpulse.dev');

  setUp(() {
    biometrics = _MockBiometricService();
    settings = _MockSettingsStore();
    auth = _MockAuthRepository();
  });

  AppLockBloc build() =>
      AppLockBloc(biometrics: biometrics, settings: settings, auth: auth);

  group('AppLockBloc', () {
    blocTest<AppLockBloc, AppLockState>(
      'блокирует приложение, если биометрия включена и есть сессия',
      setUp: () {
        when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
        when(() => settings.biometricEnabled).thenReturn(true);
        when(() => auth.currentUser).thenReturn(user);
      },
      build: build,
      act: (bloc) => bloc.add(const AppLockStarted()),
      expect: () => [
        const AppLockState(biometricAvailable: true, isLocked: true),
      ],
    );

    blocTest<AppLockBloc, AppLockState>(
      'не блокирует, если биометрия выключена в настройках',
      setUp: () {
        when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
        when(() => settings.biometricEnabled).thenReturn(false);
        when(() => auth.currentUser).thenReturn(user);
      },
      build: build,
      act: (bloc) => bloc.add(const AppLockStarted()),
      expect: () => [
        const AppLockState(biometricAvailable: true, isLocked: false),
      ],
    );

    blocTest<AppLockBloc, AppLockState>(
      'уходит в фон — блокируется, успешный Face ID — разблокирует',
      setUp: () {
        when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
        when(() => settings.biometricEnabled).thenReturn(true);
        when(() => auth.currentUser).thenReturn(user);
        when(() => biometrics.authenticate())
            .thenAnswer((_) async => const Ok<void>(null));
      },
      build: build,
      act: (bloc) async {
        bloc
          ..add(const AppLockStarted())
          ..add(const AppLockRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AppLockUnlockRequested());
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AppLockState(biometricAvailable: true, isLocked: true),
        const AppLockState(
          biometricAvailable: true,
          isLocked: true,
          isVerifying: true,
        ),
        const AppLockState(biometricAvailable: true, isLocked: false),
      ],
    );

    blocTest<AppLockBloc, AppLockState>(
      'считает неудачные попытки и блокирует кнопку после пяти',
      setUp: () {
        when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
        when(() => settings.biometricEnabled).thenReturn(true);
        when(() => auth.currentUser).thenReturn(user);
        when(() => biometrics.authenticate()).thenAnswer(
          (_) async =>
              const Err<void>(ValidationFailure('Отпечаток не распознан')),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const AppLockUnlockRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<AppLockState>().having(
          (state) => state.isVerifying,
          'isVerifying',
          true,
        ),
        isA<AppLockState>()
            .having((state) => state.failedAttempts, 'failedAttempts', 1)
            .having((state) => state.error, 'error', contains('Отпечаток')),
      ],
    );
  });
}
