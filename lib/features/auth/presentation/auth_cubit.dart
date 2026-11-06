import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core_network/core_network.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';
import 'package:fieldpulse/features/auth/domain/entities/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.fieldErrors = const {},
    this.isSubmitting = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    bool clearError = false,
    bool clearUser = false,
  }) => AuthState(
    status: status ?? this.status,
    user: clearUser ? null : user ?? this.user,
    error: clearError ? null : error ?? this.error,
    fieldErrors: clearError ? const {} : fieldErrors ?? this.fieldErrors,
    isSubmitting: isSubmitting ?? this.isSubmitting,
  );

  @override
  List<Object?> get props => [status, user, error, fieldErrors, isSubmitting];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository repository})
    : _repository = repository,
      super(const AuthState());

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  void start() {
    _subscription ??= _repository.watchUser().listen((user) {
      emit(
        state.copyWith(
          status: user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          user: user,
          clearUser: user == null,
          clearError: true,
        ),
      );
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    if (state.isSubmitting) {
      return;
    }
    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await _repository.signIn(email: email, password: password);
    result.fold(
      ok: (_) => emit(state.copyWith(isSubmitting: false, clearError: true)),
      err: (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          error: failure.message,
          fieldErrors: failure is ValidationFailure
              ? failure.fieldErrors
              : const {},
        ),
      ),
    );
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
