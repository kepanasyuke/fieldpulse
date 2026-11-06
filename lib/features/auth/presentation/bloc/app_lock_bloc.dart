import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fieldpulse/core/native/biometric_service.dart';
import 'package:core_storage/core_storage.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';

sealed class AppLockEvent {
  const AppLockEvent();
}

final class AppLockStarted extends AppLockEvent {
  const AppLockStarted();
}

final class AppLockRequested extends AppLockEvent {
  const AppLockRequested();
}

final class AppLockUnlockRequested extends AppLockEvent {
  const AppLockUnlockRequested();
}

final class AppLockReleased extends AppLockEvent {
  const AppLockReleased();
}

class AppLockState extends Equatable {
  const AppLockState({
    this.isLocked = false,
    this.biometricAvailable = false,
    this.isVerifying = false,
    this.error,
    this.failedAttempts = 0,
  });

  final bool isLocked;
  final bool biometricAvailable;
  final bool isVerifying;
  final String? error;
  final int failedAttempts;

  bool get canRetry => failedAttempts < 5;

  AppLockState copyWith({
    bool? isLocked,
    bool? biometricAvailable,
    bool? isVerifying,
    String? error,
    int? failedAttempts,
    bool clearError = false,
  }) => AppLockState(
    isLocked: isLocked ?? this.isLocked,
    biometricAvailable: biometricAvailable ?? this.biometricAvailable,
    isVerifying: isVerifying ?? this.isVerifying,
    error: clearError ? null : error ?? this.error,
    failedAttempts: failedAttempts ?? this.failedAttempts,
  );

  @override
  List<Object?> get props => [
    isLocked,
    biometricAvailable,
    isVerifying,
    error,
    failedAttempts,
  ];
}

class AppLockBloc extends Bloc<AppLockEvent, AppLockState> {
  AppLockBloc({
    required BiometricService biometrics,
    required SettingsStore settings,
    required AuthRepository auth,
  }) : _biometrics = biometrics,
       _settings = settings,
       _auth = auth,
       super(const AppLockState()) {
    on<AppLockStarted>(_onStarted);
    on<AppLockRequested>(_onRequested);
    on<AppLockUnlockRequested>(_onUnlockRequested);
    on<AppLockReleased>(_onReleased);
  }

  final BiometricService _biometrics;
  final SettingsStore _settings;
  final AuthRepository _auth;

  Future<void> _onStarted(
    AppLockStarted event,
    Emitter<AppLockState> emit,
  ) async {
    final available = await _biometrics.isAvailable();
    emit(
      state.copyWith(
        biometricAvailable: available,
        isLocked:
            available &&
            _settings.biometricEnabled &&
            _auth.currentUser != null,
      ),
    );
  }

  void _onRequested(AppLockRequested event, Emitter<AppLockState> emit) {
    if (!state.biometricAvailable ||
        !_settings.biometricEnabled ||
        _auth.currentUser == null) {
      return;
    }
    emit(state.copyWith(isLocked: true, clearError: true));
  }

  Future<void> _onUnlockRequested(
    AppLockUnlockRequested event,
    Emitter<AppLockState> emit,
  ) async {
    if (state.isVerifying || !state.canRetry) {
      return;
    }
    emit(state.copyWith(isVerifying: true, clearError: true));

    final result = await _biometrics.authenticate();
    result.fold(
      ok: (_) => emit(
        state.copyWith(
          isVerifying: false,
          isLocked: false,
          failedAttempts: 0,
          clearError: true,
        ),
      ),
      err: (failure) => emit(
        state.copyWith(
          isVerifying: false,
          error: failure.message,
          failedAttempts: state.failedAttempts + 1,
        ),
      ),
    );
  }

  void _onReleased(AppLockReleased event, Emitter<AppLockState> emit) {
    emit(state.copyWith(isLocked: false, failedAttempts: 0, clearError: true));
  }
}
