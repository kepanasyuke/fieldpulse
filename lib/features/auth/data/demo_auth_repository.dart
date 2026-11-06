import 'dart:async';

import 'package:core_network/core_network.dart';
import 'package:core_storage/core_storage.dart';
import 'package:fieldpulse/features/auth/domain/auth_repository.dart';
import 'package:fieldpulse/features/auth/domain/entities/auth_user.dart';

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._tokenStore);

  static const AuthUser _demoUser = AuthUser(
    uid: 'demo-engineer',
    email: 'engineer@fieldpulse.dev',
    displayName: 'Демо-инженер',
    roles: ['engineer'],
  );

  final SecureTokenStore _tokenStore;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> watchUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      return const Err(
        ValidationFailure(
          'Пароль короче 6 символов',
          fieldErrors: {'password': 'Минимум 6 символов'},
        ),
      );
    }
    await _tokenStore.saveTokens(access: 'demo-token', refresh: 'demo-refresh');
    _user = _demoUser;
    _controller.add(_user);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> signOut() async {
    await _tokenStore.clearTokens();
    _user = null;
    _controller.add(null);
    return const Ok<void>(null);
  }

  @override
  Future<String?> idToken() async => _user == null
      ? null
      : await _tokenStore.readAccessToken() ?? 'demo-token';
}
