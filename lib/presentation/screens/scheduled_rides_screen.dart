import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../bloc/scheduled_rides/scheduled_rides_cubit.dart';
import '../../bloc/scheduled_rides/scheduled_rides_state.dart';
import '../../models/ride.dart';
import '../../repository/ride_repository.dart';
import '../../repository/rider_repository.dart';
import '../widgets/glass_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class ScheduledRidesScreen extends StatelessWidget {
  final String riderId;
  const ScheduledRidesScreen({super.key, required this.riderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduledRidesCubit(
        context.read<RiderRepository>(),
        context.read<RideRepository>(),
        riderId,
      ),
      child: const _ScheduledRidesView(),
    );
  }
}

class _ScheduledRidesView extends StatelessWidget {
  const _ScheduledRidesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Scheduled Rides',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 300))
                .slideY(
                  begin: -0.2,
                  end: 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
            // Content
            Expanded(
              child: BlocBuilder<ScheduledRidesCubit, ScheduledRidesState>(
                builder: (context, state) {
                  return switch (state) {
                    ScheduledRidesLoading() => const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
                        ),
                      ),
                    ScheduledRidesError(:final message) => Center(
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
                                  message,
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
                      ),
                    ScheduledRidesLoaded(:final rides) => rides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.event_note,
                                    size: 40,
                                    color: Color(0xFF8A8A9A),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                      duration:
                                          const Duration(milliseconds: 300),
                                    )
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      end: const Offset(1, 1),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    ),
                                const SizedBox(height: 24),
                                const Text(
                                  'No scheduled rides',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                    color: Colors.white,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                      delay:
                                          const Duration(milliseconds: 100),
                                      duration:
                                          const Duration(milliseconds: 300),
                                    )
                                    .slideY(
                                      begin: 0.2,
                                      end: 0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You have no upcoming rides',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.1,
                                    color: Color(0xFF8A8A9A),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                      delay:
                                          const Duration(milliseconds: 150),
                                      duration:
                                          const Duration(milliseconds: 300),
                                    )
                                    .slideY(
                                      begin: 0.2,
                                      end: 0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: rides.length,
                            separatorBuilder: (_, sep) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) => _RideCard(
                              ride: rides[index],
                            )
                                .animate()
                                .fadeIn(
                                  delay: Duration(
                                      milliseconds: 50 * index),
                                  duration: const Duration(milliseconds: 300),
                                )
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                          ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final dateStr = ride.scheduledAt != null
        ? DateFormat('EEE, MMM d · h:mm a').format(ride.scheduledAt!.toLocal())
        : 'Unknown time';

    final statusColor = switch (ride.status) {
      'scheduled' => const Color(0xFF6C63FF),
      'accepted' => const Color(0xFF00E5C3),
      'cancelled' => const Color(0xFFFF4757),
      'completed' => const Color(0xFF8A8A9A),
      'rejected' => const Color(0xFFFF9A3C),
      _ => const Color(0xFF8A8A9A),
    };

    final isActive = ride.status == 'scheduled' ||
        ride.status == 'accepted' ||
        ride.status == 'requested';

    final canCancel = isActive &&
        ride.scheduledAt != null &&
        ride.scheduledAt!.isAfter(
          DateTime.now().add(const Duration(hours: 1)),
        );

    final isWithinHour = isActive &&
        ride.scheduledAt != null &&
        !ride.scheduledAt!.isAfter(
          DateTime.now().add(const Duration(hours: 1)),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: date + status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  (ride.status ?? 'unknown').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.trip_origin,
                size: 16,
                color: Color(0xFF00E5C3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.pickupAddress ??
                      '${ride.pickup.latitude.toStringAsFixed(4)}, ${ride.pickup.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Drop
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Color(0xFFFF4757),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.dropAddress ??
                      '${ride.drop.latitude.toStringAsFixed(4)}, ${ride.drop.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ),
            ],
          ),
          // Distance
          if (ride.distanceKm > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.route,
                  size: 16,
                  color: Color(0xFF8A8A9A),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ride.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ],
          // Cancel button or locked message
          if (canCancel) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                text: 'Cancel Ride',
                danger: true,
                onPressed: () => _confirmCancel(context),
              ),
            ),
          ],
          if (isWithinHour) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8A8A9A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8A8A9A).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Color(0xFF8A8A9A),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cannot cancel within 1 hour of ride',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF12121A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cancel Scheduled Ride?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This will cancel the ride and notify the customer.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                  color: Color(0xFF8A8A9A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'No',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Yes, Cancel',
                      danger: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        context
                            .read<ScheduledRidesCubit>()
                            .cancelScheduledRide(ride.id, ride.customerId);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
