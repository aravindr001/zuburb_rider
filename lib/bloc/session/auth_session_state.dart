import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthSessionState {
  const AuthSessionState();
}

class AuthSessionUnknown extends AuthSessionState {
  const AuthSessionUnknown();
}

class AuthSessionUnauthenticated extends AuthSessionState {
  const AuthSessionUnauthenticated();
}

class AuthSessionAuthenticated extends AuthSessionState {
  final User user;
  const AuthSessionAuthenticated(this.user);
}
