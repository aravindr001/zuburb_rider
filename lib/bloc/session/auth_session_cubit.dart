import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/auth_repository.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> {
  final AuthRepository _authRepository;
  StreamSubscription? _sub;

  AuthSessionCubit(this._authRepository) : super(const AuthSessionUnknown()) {
    _sub = _authRepository.authStateChanges().listen((user) {
      if (user == null) {
        emit(const AuthSessionUnauthenticated());
      } else {
        emit(AuthSessionAuthenticated(user));
      }
    });
  }

  Future<void> signOut() => _authRepository.signOut();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
