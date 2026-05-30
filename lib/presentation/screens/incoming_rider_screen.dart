import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../bloc/incoming_ride/incoming_ride_cubit.dart';
import '../../bloc/incoming_ride/incoming_ride_state.dart';
import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../repository/ride_repository.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/pulsing_indicator.dart';
import 'ride_navigation_screen.dart';

class IncomingRideScreen extends StatefulWidget {
  final String rideId;

  const IncomingRideScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<IncomingRideScreen> createState() => _IncomingRideScreenState();
}

class _IncomingRideScreenState extends State<IncomingRideScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AuthSessionCubit>().state;
    if (sessionState is! AuthSessionAuthenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider(
      create: (context) => IncomingRideCubit(
        context.read<RideRepository>(),
        rideId: widget.rideId,
        riderId: sessionState.user.uid,
      ),
      child: const _IncomingRideView(),
    );
  }
}

class _IncomingRideView extends StatelessWidget {
  const _IncomingRideView();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: BlocConsumer<IncomingRideCubit, IncomingRideState>(
          listener: (context, state) {
            if (state is IncomingRideNotFound) {
              Navigator.of(context).popUntil((route) => route.isFirst);
              return;
            }
            if (state is IncomingRideCompleted && state.action == 'rejected') {
              Navigator.of(context).popUntil((route) => route.isFirst);
              return;
            }
            if (state is IncomingRideError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: const Color(0xFFFF4757),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is IncomingRideLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
                ),
              );
            }

            if (state is IncomingRideNotFound) {
              return const Center(
                child: Text(
                  "Ride not found",
                  style: TextStyle(
                    color: Color(0xFF8A8A9A),
                    fontSize: 16,
                  ),
                ),
              );
            }

            if (state is IncomingRideLoaded) {
              final ride = state.ride;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Urgent pulsing indicator with extra effects
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background glow effect
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF00E5C3).withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          )
                              .animate(
                                  onPlay: (controller) => controller.repeat())
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeInOut,
                              )
                              .fade(
                                begin: 0.5,
                                end: 0.0,
                                duration: const Duration(milliseconds: 1500),
                              ),
                          const PulsingIndicator(size: 160),
                        ],
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.03, 1.03),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                          ),
                      const SizedBox(height: 40),
                      // Urgent title with shimmer
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF00E5C3),
                            Color(0xFF00FFF0),
                            Color(0xFF00E5C3)
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'INCOMING RIDE REQUEST',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(
                            delay: const Duration(milliseconds: 100),
                            duration: const Duration(milliseconds: 300),
                          )
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          )
                          .then()
                          .shimmer(
                            duration: const Duration(milliseconds: 2000),
                            color: Colors.white.withOpacity(0.5),
                          ),
                      const SizedBox(height: 48),
                      // Ride details
                      GlassCard(
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: Icons.trip_origin,
                              label: 'PICKUP',
                              value: (ride.pickupAddress?.isNotEmpty ?? false)
                                  ? ride.pickupAddress!
                                  : '${ride.pickup.latitude.toStringAsFixed(6)}, ${ride.pickup.longitude.toStringAsFixed(6)}',
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.08),
                            ),
                            const SizedBox(height: 20),
                            _buildDetailRow(
                              icon: Icons.location_on,
                              label: 'DROP',
                              value: (ride.dropAddress?.isNotEmpty ?? false)
                                  ? ride.dropAddress!
                                  : '${ride.drop.latitude.toStringAsFixed(6)}, ${ride.drop.longitude.toStringAsFixed(6)}',
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.08),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00E5C3)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.route,
                                        color: Color(0xFF00E5C3),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'DISTANCE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.2,
                                        color: Color(0xFF8A8A9A),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${ride.distanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (ride.isScheduled) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF6C63FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Color(0xFF6C63FF),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'SCHEDULED RIDE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                        color: Color(0xFF6C63FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                            delay: const Duration(milliseconds: 200),
                            duration: const Duration(milliseconds: 300),
                          )
                          .slideY(
                            begin: 0.2,
                            end: 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                      const Spacer(),
                      // Action buttons
                      if (state.actionInProgress)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
                          ),
                        )
                      else if (ride.isScheduled)
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: 'Start Ride',
                            onPressed: () async {
                              await context.read<IncomingRideCubit>().accept();
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RideNavigationScreen(
                                    rideId: ride.id,
                                    pickupLat: ride.pickup.latitude,
                                    pickupLng: ride.pickup.longitude,
                                    dropLat: ride.drop.latitude,
                                    dropLng: ride.drop.longitude,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: PrimaryButton(
                                text: 'Accept',
                                onPressed: () async {
                                  await context
                                      .read<IncomingRideCubit>()
                                      .accept();
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RideNavigationScreen(
                                        rideId: ride.id,
                                        pickupLat: ride.pickup.latitude,
                                        pickupLng: ride.pickup.longitude,
                                        dropLat: ride.drop.latitude,
                                        dropLng: ride.drop.longitude,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: SecondaryButton(
                                text: 'Reject',
                                danger: true,
                                onPressed: () =>
                                    context.read<IncomingRideCubit>().reject(),
                              ),
                            ),
                          ],
                        )
                              .animate()
                              .fadeIn(
                                delay: const Duration(milliseconds: 300),
                                duration: const Duration(milliseconds: 300),
                              )
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              ),
                    ],
                  ),
                ),
              );
            }

            if (state is IncomingRideError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF4757),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5C3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00E5C3),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: Color(0xFF8A8A9A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
