import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:fieldpulse/core/error/failure.dart';
import 'package:fieldpulse/core/storage/secure_token_store.dart';
import 'package:fieldpulse/core/utils/result.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';
import 'package:fieldpulse/features/auth/domain/entities/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth auth,
    required SecureTokenStore tokenStore,
  }) : _auth = auth,
       _tokenStore = tokenStore;

  final FirebaseAuth _auth;
  final SecureTokenStore _tokenStore;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> watchUser() => _auth.authStateChanges().map(_mapUser);

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final token = await credential.user?.getIdToken();
      if (token != null) {
        await _tokenStore.saveTokens(
          access: token,
          refresh: credential.user?.refreshToken,
        );
      }
      return const Ok<void>(null);
    } on FirebaseAuthException catch (error) {
      return Err(_mapAuthException(error));
    } on Exception catch (error) {
      return Err(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      await _tokenStore.clearTokens();
      return const Ok<void>(null);
    } on Exception catch (error) {
      return Err(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<String?> idToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    final token = await user.getIdToken();
    final stored = await _tokenStore.readAccessToken();
    if (token != null && token != stored) {
      await _tokenStore.saveTokens(access: token);
    }
    return token;
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      roles: const ['engineer'],
    );
  }

  Failure _mapAuthException(FirebaseAuthException error) =>
      switch (error.code) {
        'invalid-email' => const ValidationFailure(
          'Некорректный адрес почты',
          fieldErrors: {'email': 'Проверьте формат адреса'},
        ),
        'user-disabled' => const UnauthorizedFailure(
          'Учётная запись заблокирована',
        ),
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => const ValidationFailure(
          'Неверная почта или пароль',
          fieldErrors: {'password': 'Проверьте пароль'},
        ),
        'too-many-requests' => const UnauthorizedFailure(
          'Слишком много попыток, попробуйте позже',
        ),
        'network-request-failed' => const NetworkFailure(),
        _ => UnknownFailure(error.message ?? 'Не удалось выполнить вход'),
      };
}
