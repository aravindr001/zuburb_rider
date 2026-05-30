import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/ride_navigation/ride_navigation_cubit.dart';
import '../../bloc/ride_navigation/ride_navigation_state.dart';
import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../models/ride.dart';
import '../../repository/directions_repository.dart';
import '../../repository/ride_repository.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class RideNavigationScreen extends StatelessWidget {
  final String rideId;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const RideNavigationScreen({
    super.key,
    required this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RideNavigationCubit(DirectionsRepository()),
      child: _RideNavigationView(
        rideId: rideId,
        pickupLocation: LatLng(pickupLat, pickupLng),
        dropoffLocation: LatLng(dropLat, dropLng),
      ),
    );
  }
}

class _RideNavigationView extends StatefulWidget {
  final String rideId;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;

  const _RideNavigationView({
    required this.rideId,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  State<_RideNavigationView> createState() => _RideNavigationViewState();
}

class _RideNavigationViewState extends State<_RideNavigationView> {
  GoogleMapController? _mapController;
  bool _cameraFittedOnce = false;
  bool _cancelInProgress = false;
  bool _completeInProgress = false;
  bool _toDropoff = false;

  void _switchToDropoffIfNeeded() {
    if (_toDropoff) return;
    setState(() {
      _toDropoff = true;
      _cameraFittedOnce = false;
    });
    context
        .read<RideNavigationCubit>()
        .load(pickupLocation: widget.dropoffLocation);
  }

  Future<void> _showPickupOtpDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PickupOtpDialog(rideId: widget.rideId),
    );

    if (!mounted) return;
    if (ok == true) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Pickup verified'),
          backgroundColor: Color(0xFF00E5C3),
        ),
      );
    }
  }

  Future<void> _openGoogleMaps({LatLng? origin}) async {
    final params = <String, String>{
      'api': '1',
      'travelmode': 'driving',
      'destination':
          '${widget.dropoffLocation.latitude},${widget.dropoffLocation.longitude}',
    };

    if (origin != null) {
      params['origin'] = '${origin.latitude},${origin.longitude}';
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps'),
          backgroundColor: Color(0xFFFF4757),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<RideNavigationCubit>()
          .load(pickupLocation: widget.pickupLocation);
    });
  }

  Future<void> _fitCamera(LatLng a, LatLng b) async {
    if (_mapController == null || _cameraFittedOnce) return;
    _cameraFittedOnce = true;

    final southWest = LatLng(
      a.latitude < b.latitude ? a.latitude : b.latitude,
      a.longitude < b.longitude ? a.longitude : b.longitude,
    );
    final northEast = LatLng(
      a.latitude > b.latitude ? a.latitude : b.latitude,
      a.longitude > b.longitude ? a.longitude : b.longitude,
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southWest, northeast: northEast),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AuthSessionCubit>().state;

    return BlocConsumer<RideNavigationCubit, RideNavigationState>(
      listener: (context, state) {
        if (state is RideNavigationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFFF4757),
            ),
          );
        }
        if (state is RideNavigationLoaded) {
          _fitCamera(state.riderLocation, state.pickupLocation);
        }
      },
      builder: (context, state) {
        final destination =
            _toDropoff ? widget.dropoffLocation : widget.pickupLocation;
        final destinationMarker = Marker(
          markerId: MarkerId(_toDropoff ? 'dropoff' : 'pickup'),
          position: destination,
          infoWindow: InfoWindow(title: _toDropoff ? 'Dropoff' : 'Pickup'),
        );

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A0F),
            body: Stack(
              children: [
                // Map fills entire screen
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: destination,
                    zoom: 14,
                  ),
                  myLocationEnabled: state is RideNavigationLoaded,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (state is RideNavigationLoaded) {
                      _fitCamera(state.riderLocation, state.pickupLocation);
                    }
                  },
                  markers: state is RideNavigationLoaded
                      ? {...state.markers, destinationMarker}
                      : {destinationMarker},
                  polylines: state is RideNavigationLoaded
                      ? state.polylines
                      : const <Polyline>{},
                ),
                // Top status card (floating over map)
                Positioned(
                  left: 16,
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF12121A).withOpacity(0.85),
                              const Color(0xFF12121A).withOpacity(0.75),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF00E5C3).withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5C3).withOpacity(0.15),
                              blurRadius: 24,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00E5C3).withOpacity(0.2),
                                    const Color(0xFF00E5C3).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF00E5C3).withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                _toDropoff
                                    ? Icons.location_on
                                    : Icons.trip_origin,
                                color: const Color(0xFF00E5C3),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _toDropoff
                                        ? 'NAVIGATE TO DROPOFF'
                                        : 'NAVIGATE TO PICKUP',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF00E5C3),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00E5C3),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                          .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true))
                                          .fade(
                                            begin: 0.3,
                                            end: 1.0,
                                            duration: const Duration(
                                                milliseconds: 800),
                                          ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Active ride in progress',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.3,
                                          color: Color(0xFFB0B0BA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 400))
                      .slideY(
                        begin: -0.3,
                        end: 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                      ),
                ),
                // Loading overlay
                if (state is RideNavigationLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00E5C3)),
                    ),
                  ),
                // Error banner
                if (state is RideNavigationError)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF4757).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            state.message,
                            style: const TextStyle(
                              color: Color(0xFFFF4757),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Bottom action sheet (floating over map)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: StreamBuilder<Ride?>(
                      stream: context
                          .read<RideRepository>()
                          .watchRide(widget.rideId),
                      builder: (context, snapshot) {
                        final ride = snapshot.data;
                        final status = ride?.status;
                        final otp = ride?.pickupOtp;
                        final verified = ride?.pickupOtpVerified == true;

                        if (status == 'cancelled') {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          });
                        }

                        final pickedUp = status == 'picked_up';
                        final canNavigateDropoff = verified || pickedUp;

                        if (canNavigateDropoff && !_toDropoff) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _switchToDropoffIfNeeded();
                          });
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF12121A).withOpacity(0.95),
                                    const Color(0xFF0A0A0F).withOpacity(0.95),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 32,
                                    spreadRadius: 0,
                                    offset: const Offset(0, -8),
                                  ),
                                ],
                              ),
                              child: _buildActions(
                                context,
                                sessionState,
                                state,
                                canNavigateDropoff,
                                status,
                                otp,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: const Duration(milliseconds: 150),
                              duration: const Duration(milliseconds: 400),
                            )
                            .slideY(
                              begin: 0.3,
                              end: 0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(
    BuildContext context,
    AuthSessionState sessionState,
    RideNavigationState state,
    bool canNavigateDropoff,
    String? status,
    String? otp,
  ) {
    Widget topCta;

    if (canNavigateDropoff) {
      if (_toDropoff) {
        topCta = PrimaryButton(
          text: 'Complete Dropoff',
          loading: _completeInProgress,
          onPressed: (_completeInProgress ||
                  sessionState is! AuthSessionAuthenticated)
              ? null
              : () async {
                  setState(() => _completeInProgress = true);
                  try {
                    final riderId = sessionState.user.uid;
                    await context.read<RideRepository>().completeDropoff(
                          rideId: widget.rideId,
                          riderId: riderId,
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    setState(() => _completeInProgress = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: const Color(0xFFFF4757),
                      ),
                    );
                  }
                },
        );
      } else {
        topCta = PrimaryButton(
          text: 'Pickup Complete',
          onPressed: null,
        );
      }
    } else if (status == 'arrived_pickup') {
      if (otp == null || otp.trim().isEmpty) {
        topCta = PrimaryButton(
          text: 'Waiting for OTP…',
          onPressed: null,
        );
      } else {
        topCta = PrimaryButton(
          text: 'Verify Pickup OTP',
          onPressed: _showPickupOtpDialog,
        );
      }
    } else {
      topCta = PrimaryButton(
        text: 'Reached Pickup Location',
        onPressed: () async {
          try {
            await context
                .read<RideRepository>()
                .markArrivedAtPickup(rideId: widget.rideId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Arrived at pickup. Waiting for OTP…'),
                backgroundColor: Color(0xFF00E5C3),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: const Color(0xFFFF4757),
              ),
            );
          }
        },
      );
    }

    final origin = switch (state) {
      RideNavigationLoaded(:final riderLocation) => riderLocation,
      _ => null,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: double.infinity, child: topCta),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Navigate',
                onPressed: canNavigateDropoff
                    ? () {
                        if (!_toDropoff) {
                          _switchToDropoffIfNeeded();
                        }
                        _openGoogleMaps(origin: origin);
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                text: 'Cancel',
                danger: true,
                loading: _cancelInProgress,
                onPressed:
                    (_cancelInProgress || sessionState is! AuthSessionAuthenticated)
                        ? null
                        : () async {
                            setState(() => _cancelInProgress = true);
                            try {
                              final riderId = sessionState.user.uid;
                              await context.read<RideRepository>().cancelRide(
                                    rideId: widget.rideId,
                                    riderId: riderId,
                                  );
                              if (!context.mounted) return;
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _cancelInProgress = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: const Color(0xFFFF4757),
                                ),
                              );
                            }
                          },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickupOtpDialog extends StatefulWidget {
  final String rideId;

  const _PickupOtpDialog({required this.rideId});

  @override
  State<_PickupOtpDialog> createState() => _PickupOtpDialogState();
}

class _PickupOtpDialogState extends State<_PickupOtpDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _controller.text.trim();
    final valid = RegExp(r'^\d{4}$').hasMatch(otp);
    if (!valid) {
      setState(() {
        _errorText = 'Enter a 4-digit OTP';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await context.read<RideRepository>().verifyPickupOtp(
            rideId: widget.rideId,
            otp: otp,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF12121A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter Pickup OTP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                counterText: '',
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFF0A0A0F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF00E5C3),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF4757),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_errorText == null) return;
                setState(() {
                  _errorText = null;
                });
              },
              onSubmitted: (_) {
                if (!_submitting) _submit();
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Cancel',
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: 'Verify',
                    loading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
