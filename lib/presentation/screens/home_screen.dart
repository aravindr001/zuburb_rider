import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zuburb_rider/presentation/screens/incoming_rider_screen.dart';
import 'package:zuburb_rider/presentation/screens/ride_navigation_screen.dart';
import 'package:zuburb_rider/presentation/screens/rider_availability_screen.dart';
import 'package:zuburb_rider/presentation/screens/scheduled_rides_screen.dart';
import 'package:zuburb_rider/presentation/widgets/glass_card.dart';
import 'package:zuburb_rider/presentation/widgets/online_toggle.dart';
import 'package:zuburb_rider/presentation/widgets/pulsing_indicator.dart';

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
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator()),
      );
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
      context.read<BackgroundLocationCubit>().start(widget.riderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      drawer: _buildDrawer(context),
      body: MultiBlocListener(
        listeners: [
          BlocListener<LocationPermissionCubit, LocationPermissionState>(
            listenWhen: (previous, current) => current is! LocationPermissionInitial,
            listener: (context, state) {
              if (state is LocationPermissionServiceDisabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enable location services.'),
                    backgroundColor: Color(0xFFFF4757),
                  ),
                );
              }
              if (state is LocationPermissionDenied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location permission is required.'),
                    backgroundColor: Color(0xFFFF4757),
                  ),
                );
              }
              if (state is LocationPermissionPermanentlyDenied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enable location permission in Settings.'),
                    backgroundColor: Color(0xFFFF4757),
                  ),
                );
              }
            },
          ),
          BlocListener<BackgroundLocationCubit, BackgroundLocationState>(
            listener: (context, state) {
              if (state is BackgroundLocationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: const Color(0xFFFF4757),
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
            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(child: _buildContent(context, state)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
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
              child: const Icon(Icons.menu, color: Colors.white, size: 24),
            ),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00E5C3), Color(0xFF6C63FF)],
            ).createShader(bounds),
            child: const Text(
              'GUARD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
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
        );
  }

  Widget _buildContent(BuildContext context, RiderHomeState state) {
    return switch (state) {
      RiderHomeLoading() => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
          ),
        ),
      RiderHomeWaiting() => _buildWaitingState(context),
      RiderHomeIncomingRide() => _buildIncomingState(),
      RiderHomeActiveRide() => _buildActiveRideState(),
      RiderHomeError(:final message) => _buildErrorState(message),
    };
  }

  Widget _buildWaitingState(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          BlocBuilder<RiderOnlineCubit, bool>(
            builder: (context, isOnline) {
              return Column(
                children: [
                  OnlineToggle(
                    isOnline: isOnline,
                    onChanged: (value) async {
                      final riderOnlineCubit = context.read<RiderOnlineCubit>();
                      final messenger = ScaffoldMessenger.of(context);

                      if (value) {
                        final serviceEnabled =
                            await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          if (!context.mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Please enable location services.'),
                              backgroundColor: Color(0xFFFF4757),
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
                              backgroundColor: Color(0xFFFF4757),
                            ),
                          );
                          return;
                        }
                      }

                      await riderOnlineCubit.setOnline(value);
                    },
                  ),
                  const SizedBox(height: 32),
                  // Animated status indicator
                  if (isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E5C3).withOpacity(0.1),
                            const Color(0xFF00E5C3).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF00E5C3).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E5C3),
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fade(
                                begin: 0.3,
                                end: 1.0,
                                duration: const Duration(milliseconds: 800),
                              ),
                          const SizedBox(width: 12),
                          const Text(
                            'READY FOR RIDES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Color(0xFF00E5C3),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(key: const ValueKey('online'))
                        .fadeIn(duration: const Duration(milliseconds: 300))
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        )
                        .then()
                        .shimmer(
                          duration: const Duration(milliseconds: 2000),
                          color: const Color(0xFF00E5C3).withOpacity(0.3),
                        ),
                ],
              )
                  .animate()
                  .fadeIn(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 400),
                  )
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1, 1),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                  );
            },
          ),
          const SizedBox(height: 32),
          BlocBuilder<RiderOnlineCubit, bool>(
            builder: (context, isOnline) {
              return Text(
                isOnline
                    ? 'Listening for new ride requests in your area'
                    : 'Go online to start receiving ride requests',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  color: Color(0xFF8A8A9A),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(
                    key: ValueKey(isOnline),
                  )
                  .fadeIn(duration: const Duration(milliseconds: 300))
                  .slideY(
                    begin: 0.15,
                    end: 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
            },
          ),
          const SizedBox(height: 56),
          _ScheduledRidesCard(riderId: widget.riderId)
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 250),
                duration: const Duration(milliseconds: 400),
              )
              .slideY(
                begin: 0.2,
                end: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }

  Widget _buildIncomingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingIndicator(size: 120)
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 300))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 32),
          const Text(
            'INCOMING RIDE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF00E5C3),
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 300),
              )
              .slideY(
                begin: 0.2,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 12),
          const Text(
            'Opening ride details...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
              color: Color(0xFF8A8A9A),
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 150),
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
    );
  }

  Widget _buildActiveRideState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 300))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 24),
          const Text(
            'Resuming active ride...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
              color: Color(0xFF8A8A9A),
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 100),
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
    );
  }

  Widget _buildErrorState(String message) {
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
      )
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 300))
          .slideY(
            begin: 0.2,
            end: 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0F),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00E5C3), Color(0xFF6C63FF)],
              ).createShader(bounds),
              child: const Text(
                'GUARD',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rider',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
                color: Color(0xFF8A8A9A),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFF12121A)),
            BlocBuilder<ScheduledRidesCubit, ScheduledRidesState>(
              builder: (context, state) {
                final count = state is ScheduledRidesLoaded ? state.count : 0;
                return ListTile(
                  leading: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    backgroundColor: const Color(0xFF00E5C3),
                    textColor: const Color(0xFF0A0A0F),
                    child: const Icon(Icons.event_note, color: Colors.white),
                  ),
                  title: const Text(
                    'Scheduled Rides',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ScheduledRidesScreen(riderId: widget.riderId),
                      ),
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.white),
              title: const Text(
                'Availability & Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RiderAvailabilityScreen(riderId: widget.riderId),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFF12121A)),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFFF4757)),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFF4757),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<BackgroundLocationCubit>().stop();
                context.read<AuthSessionCubit>().signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
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

        return GlassCard(
          onTap: count > 0
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScheduledRidesScreen(riderId: riderId),
                    ),
                  );
                }
              : null,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: count > 0
                      ? const Color(0xFF00E5C3).withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note,
                  color: count > 0 ? const Color(0xFF00E5C3) : const Color(0xFF8A8A9A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count > 0
                          ? '$count scheduled ride${count == 1 ? '' : 's'}'
                          : 'No scheduled rides',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count > 0 ? 'Tap to view' : 'You have no upcoming rides',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF8A8A9A),
                  size: 24,
                ),
            ],
          ),
        );
      },
    );
  }
}
