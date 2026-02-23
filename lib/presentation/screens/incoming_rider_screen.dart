import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/incoming_ride/incoming_ride_cubit.dart';
import '../../bloc/incoming_ride/incoming_ride_state.dart';
import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../repository/ride_repository.dart';
import 'ride_navigation_screen.dart';

class IncomingRideScreen extends StatefulWidget {
  final String rideId;

  const IncomingRideScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<IncomingRideScreen> createState() =>
      _IncomingRideScreenState();
}

class _IncomingRideScreenState
    extends State<IncomingRideScreen> {

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AuthSessionCubit>().state;
    if (sessionState is! AuthSessionAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
    return Scaffold(
      appBar: AppBar(title: const Text("Incoming Ride")),
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
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is IncomingRideLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is IncomingRideNotFound) {
            return const Center(child: Text("Ride not found"));
          }

          if (state is IncomingRideLoaded) {
            final ride = state.ride;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pickup:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${ride.pickup.latitude}, ${ride.pickup.longitude}"),
                  const SizedBox(height: 20),
                  const Text(
                    "Drop:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${ride.drop.latitude}, ${ride.drop.longitude}"),
                  const SizedBox(height: 20),
                  Text(
                    "Distance: ${ride.distanceKm.toStringAsFixed(2)} km",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  if (state.actionInProgress)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.read<IncomingRideCubit>().reject(),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text("Reject"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
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
                            child: const Text("Accept"),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }

          if (state is IncomingRideError) {
            return Center(child: Text(state.message));
          }

          if (state is IncomingRideCompleted) {
            return const SizedBox.shrink();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}