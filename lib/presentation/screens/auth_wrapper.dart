import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../models/rider_profile.dart';
import '../../repository/rider_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'rider_profile_setup_screen.dart';

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
          AuthSessionAuthenticated(:final user) => _ProfileGate(
              riderId: user.uid,
              phoneNumber: user.phoneNumber,
            ),
          AuthSessionUnauthenticated() => LoginScreen(),
        };
      },
    );
  }
}

/// Watches the rider's Firestore profile.
/// • If the document doesn't exist or is incomplete → show profile setup.
/// • If it exists with a name → show the home screen.
class _ProfileGate extends StatelessWidget {
  final String riderId;
  final String? phoneNumber;
  const _ProfileGate({required this.riderId, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RiderProfile?>(
      stream: context.read<RiderRepository>().watchRiderProfile(riderId),
      builder: (context, snapshot) {
        // Still loading the first snapshot.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;

        // No profile doc or name missing → rider needs to complete setup.
        if (profile == null || !profile.isProfileComplete) {
          return RiderProfileSetupScreen(
            riderId: riderId,
            initialPhone: phoneNumber,
          );
        }

        return const RiderHomeScreen();
      },
    );
  }
}
