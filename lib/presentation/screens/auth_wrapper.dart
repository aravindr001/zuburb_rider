import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, state) {
        return switch (state) {
          AuthSessionUnknown() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          AuthSessionAuthenticated() => const RiderHomeScreen(),
          AuthSessionUnauthenticated() => LoginScreen(),
        };
      },
    );
  }
}
