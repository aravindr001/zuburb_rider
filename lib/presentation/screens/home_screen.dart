import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zuburb_rider/presentation/screens/incoming_rider_screen.dart';
import 'package:zuburb_rider/presentation/screens/ride_navigation_screen.dart';
import 'package:zuburb_rider/presentation/screens/rider_availability_screen.dart';
import 'package:zuburb_rider/presentation/screens/scheduled_rides_screen.dart';

import '../../bloc/background_location/background_location_cubit.dart';
import '../../bloc/background_location/background_location_state.dart';
import '../../bloc/rider_home/rider_home_cubit.dart';
import '../../bloc/rider_home/rider_home_state.dart';
import '../../bloc/location_permission/location_permission_cubit.dart';
import '../../bloc/location_permission/location_permission_state.dart';
import '../../bloc/rider_online/rider_online_cubit.dart';
import '../../bloc/scheduled_rides/scheduled_rides_cubit.dart';
import '../../bloc/scheduled_rides/scheduled_rides_state.dart';
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
        BlocProvider(
          create: (context) => ScheduledRidesCubit(
            context.read<RiderRepository>(),
            context.read<RideRepository>(),
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
      // Start the background location service for this rider.
      context.read<BackgroundLocationCubit>().start(widget.riderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GUARD",style: TextStyle(letterSpacing: 6)),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // ── Online / Offline toggle ──
              BlocBuilder<RiderOnlineCubit, bool>(
                builder: (context, isOnline) {
                  return SwitchListTile(
                    secondary: Icon(
                      Icons.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                      size: 14,
                    ),
                    title: Text(isOnline ? 'Online' : 'Offline'),
                    value: isOnline,
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
                              content:
                                  Text('Please enable location services.'),
                            ),
                          );
                          return;
                        }

                        var permission =
                            await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission =
                              await Geolocator.requestPermission();
                        }

                        if (permission == LocationPermission.denied ||
                            permission ==
                                LocationPermission.deniedForever) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Location permission is required.'),
                            ),
                          );
                          return;
                        }
                      }

                      await riderOnlineCubit.setOnline(value);
                    },
                  );
                },
              ),
              const Divider(),

              // ── Scheduled Rides ──
              BlocBuilder<ScheduledRidesCubit, ScheduledRidesState>(
                builder: (context, state) {
                  final count =
                      state is ScheduledRidesLoaded ? state.count : 0;
                  return ListTile(
                    leading: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child:
                          const Icon(Icons.event_note),
                    ),
                    title: const Text('Scheduled Rides'),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduledRidesScreen(
                            riderId: widget.riderId,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // ── Availability & Schedule ──
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Availability & Schedule'),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderAvailabilityScreen(
                        riderId: widget.riderId,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),
              const Divider(),

              // ── Logout ──
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  context.read<BackgroundLocationCubit>().stop();
                  context.read<AuthSessionCubit>().signOut();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
          BlocListener<BackgroundLocationCubit, BackgroundLocationState>(
            listener: (context, state) {
              if (state is BackgroundLocationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
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

            if (state is RiderHomeActiveRide) {
              if (_lastPushedRideId == state.rideId) return;
              _lastPushedRideId = state.rideId;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RideNavigationScreen(
                    rideId: state.rideId,
                    pickupLat: state.pickupLat,
                    pickupLng: state.pickupLng,
                    dropLat: state.dropLat,
                    dropLng: state.dropLng,
                  ),
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
                      const SizedBox(height: 24),
                      _ScheduledRidesCard(riderId: widget.riderId),
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
              RiderHomeActiveRide() => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text(
                        "Resuming active ride...",
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

class _ScheduledRidesCard extends StatelessWidget {
  final String riderId;
  const _ScheduledRidesCard({required this.riderId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduledRidesCubit, ScheduledRidesState>(
      builder: (context, state) {
        final count = state is ScheduledRidesLoaded ? state.count : 0;

        if (count == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.event_note, color: Colors.grey),
                title: const Text('No scheduled rides'),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.event_note, color: Colors.blue),
              title: Text('$count scheduled ride${count == 1 ? '' : 's'}'),
              subtitle: const Text('Tap to view'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduledRidesScreen(riderId: riderId),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}