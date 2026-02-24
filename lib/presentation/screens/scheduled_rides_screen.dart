import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/scheduled_rides/scheduled_rides_cubit.dart';
import '../../bloc/scheduled_rides/scheduled_rides_state.dart';
import '../../models/ride.dart';
import '../../repository/ride_repository.dart';
import '../../repository/rider_repository.dart';

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
      appBar: AppBar(title: const Text('Scheduled Rides')),
      body: BlocBuilder<ScheduledRidesCubit, ScheduledRidesState>(
        builder: (context, state) {
          return switch (state) {
            ScheduledRidesLoading() =>
              const Center(child: CircularProgressIndicator()),
            ScheduledRidesError(:final message) =>
              Center(child: Text(message)),
            ScheduledRidesLoaded(:final rides) =>
              rides.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No scheduled rides',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: rides.length,
                      separatorBuilder: (_, sep) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _RideCard(
                        ride: rides[index],
                      ),
                    ),
          };
        },
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
      'scheduled' => Colors.blue,
      'accepted' => Colors.green,
      'cancelled' => Colors.red,
      'completed' => Colors.grey,
      'rejected' => Colors.orange,
      _ => Colors.grey,
    };

    final isActive =
        ride.status == 'scheduled' || ride.status == 'accepted' || ride.status == 'requested';

    // Rider can only cancel if the ride is more than 1 hour away.
    final canCancel = isActive &&
        ride.scheduledAt != null &&
        ride.scheduledAt!.isAfter(
          DateTime.now().add(const Duration(hours: 1)),
        );

    // Within the last hour, show a note that cancellation is locked.
    final isWithinHour = isActive &&
        ride.scheduledAt != null &&
        !ride.scheduledAt!.isAfter(
          DateTime.now().add(const Duration(hours: 1)),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: date + status chip
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (ride.status ?? 'unknown').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trip_origin, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickupAddress ??
                        '${ride.pickup.latitude.toStringAsFixed(4)}, ${ride.pickup.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Drop
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.dropAddress ??
                        '${ride.drop.latitude.toStringAsFixed(4)}, ${ride.drop.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            // Distance
            if (ride.distanceKm > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${ride.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],

            // Cancel button — only if more than 1 hour before ride
            if (canCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _confirmCancel(context),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],

            // Within 1 hour — show locked message
            if (isWithinHour) ...[
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Cannot cancel within 1 hour of ride',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Scheduled Ride?'),
        content: const Text(
            'This will cancel the ride and notify the customer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ScheduledRidesCubit>()
                  .cancelScheduledRide(ride.id, ride.customerId);
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
