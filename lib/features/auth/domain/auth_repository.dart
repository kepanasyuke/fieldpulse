import 'package:fieldpulse/core/utils/result.dart';
import 'package:fieldpulse/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> watchUser();

  AuthUser? get currentUser;

  Future<Result<void>> signIn({required String email, required String password});

  Future<Result<void>> signOut();

  Future<String?> idToken();
}
