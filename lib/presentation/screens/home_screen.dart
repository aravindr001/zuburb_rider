import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zuburb_rider/presentation/screens/incoming_rider_screen.dart';

import '../../bloc/rider_home/rider_home_cubit.dart';
import '../../bloc/rider_home/rider_home_state.dart';
import '../../bloc/location_permission/location_permission_cubit.dart';
import '../../bloc/location_permission/location_permission_state.dart';
import '../../bloc/rider_online/rider_online_cubit.dart';
import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../repository/ride_repository.dart';
import '../../repository/rider_repository.dart';


class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AuthSessionCubit>().state;
    if (sessionState is! AuthSessionAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocationPermissionCubit()),
        BlocProvider(
          create: (context) => RiderHomeCubit(
            context.read<RiderRepository>(),
            context.read<RideRepository>(),
            sessionState.user.uid,
          ),
        ),
        BlocProvider(
          create: (context) => RiderOnlineCubit(
            context.read<RiderRepository>(),
            sessionState.user.uid,
          ),
        ),
      ],
      child: _RiderHomeView(riderId: sessionState.user.uid),
    );
  }
}

class _RiderHomeView extends StatefulWidget {
  final String riderId;
  const _RiderHomeView({required this.riderId});

  @override
  State<_RiderHomeView> createState() => _RiderHomeViewState();
}

class _RiderHomeViewState extends State<_RiderHomeView> {
  String? _lastPushedRideId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationPermissionCubit>().requestWhenInUseIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // centerTitle: true,
        title: const Text("Rider Home"),
        
        actions: [
          BlocBuilder<RiderOnlineCubit, bool>(
            builder: (context, isOnline) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: isOnline,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (value) async {
                            final riderOnlineCubit =
                                context.read<RiderOnlineCubit>();
                            final messenger = ScaffoldMessenger.of(context);

                            if (value) {
                              final serviceEnabled =
                                  await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) {
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enable location services.'),
                                  ),
                                );
                                return;
                              }

                              var permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                              }

                              if (permission == LocationPermission.denied ||
                                  permission == LocationPermission.deniedForever) {
                                if (!context.mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Location permission is required.'),
                                  ),
                                );
                                return;
                              }
                            }

                            await riderOnlineCubit.setOnline(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => context.read<AuthSessionCubit>().signOut(),
            child: const Text("Logout"),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LocationPermissionCubit, LocationPermissionState>(
            listenWhen: (previous, current) => current is! LocationPermissionInitial,
            listener: (context, state) {
              if (state is LocationPermissionServiceDisabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enable location services.'),
                  ),
                );
              }
              if (state is LocationPermissionDenied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location permission is required.')),
                );
              }
              if (state is LocationPermissionPermanentlyDenied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enable location permission in Settings.'),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocConsumer<RiderHomeCubit, RiderHomeState>(
          listener: (context, state) {
            if (state is RiderHomeIncomingRide) {
              if (_lastPushedRideId == state.rideId) return;
              _lastPushedRideId = state.rideId;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IncomingRideScreen(rideId: state.rideId),
                ),
              );
            }
          },
          builder: (context, state) {
            return switch (state) {
              RiderHomeLoading() =>
                const Center(child: CircularProgressIndicator()),
              RiderHomeWaiting() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Waiting for ride requests...",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              RiderHomeIncomingRide() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Incoming ride...",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              RiderHomeError(:final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message),
                    ],
                  ),
                ),
            };
          },
        ),
      ),
    );
  }
}