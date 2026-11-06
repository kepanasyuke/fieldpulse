import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.roles = const [],
  });

  final String uid;
  final String email;
  final String? displayName;
  final List<String> roles;

  bool get isDispatcher => roles.contains('dispatcher');

  @override
  List<Object?> get props => [uid, email, displayName, roles];
}
