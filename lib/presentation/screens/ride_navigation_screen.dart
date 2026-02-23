import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/ride_navigation/ride_navigation_cubit.dart';
import '../../bloc/ride_navigation/ride_navigation_state.dart';
import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../models/ride.dart';
import '../../repository/directions_repository.dart';
import '../../repository/ride_repository.dart';

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
    context.read<RideNavigationCubit>().load(pickupLocation: widget.dropoffLocation);
  }

  Future<void> _showPickupOtpDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PickupOtpDialog(rideId: widget.rideId),
    );

    if (!mounted) return;
    if (ok == true) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Pickup verified')),
      );
    }
  }

  Future<void> _openGoogleMaps({LatLng? origin}) async {
    final params = <String, String>{
      'api': '1',
      'travelmode': 'driving',
      'destination': '${widget.dropoffLocation.latitude},${widget.dropoffLocation.longitude}',
    };

    if (origin != null) {
      params['origin'] = '${origin.latitude},${origin.longitude}';
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideNavigationCubit>().load(pickupLocation: widget.pickupLocation);
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
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is RideNavigationLoaded) {
          _fitCamera(state.riderLocation, state.pickupLocation);
        }
      },
      builder: (context, state) {
        final destination = _toDropoff ? widget.dropoffLocation : widget.pickupLocation;
        final destinationMarker = Marker(
          markerId: MarkerId(_toDropoff ? 'dropoff' : 'pickup'),
          position: destination,
          infoWindow: InfoWindow(title: _toDropoff ? 'Dropoff' : 'Pickup'),
        );

        return PopScope(
          canPop: false,
          child: Scaffold(
          appBar: AppBar(
            title: Text(_toDropoff ? 'Navigate to Dropoff' : 'Navigate to Pickup'),
            automaticallyImplyLeading: false,
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: destination,
                  zoom: 14,
                ),
                myLocationEnabled: state is RideNavigationLoaded,
                myLocationButtonEnabled: state is RideNavigationLoaded,
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
              if (state is RideNavigationLoading)
                const Center(child: CircularProgressIndicator()),
              if (state is RideNavigationError)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StreamBuilder<Ride?>(
                        stream: context.read<RideRepository>().watchRide(widget.rideId),
                        builder: (context, snapshot) {
                          final ride = snapshot.data;
                          final status = ride?.status;
                          final otp = ride?.pickupOtp;
                          final verified = ride?.pickupOtpVerified == true;

                          if (status == 'cancelled') {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            });
                          }

                          final pickedUp = status == 'picked_up';
                          final canNavigateDropoff = verified || pickedUp;

                          if (canNavigateDropoff && !_toDropoff) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _switchToDropoffIfNeeded();
                            });
                          }

                          Widget topCta;
                          if (canNavigateDropoff) {
                            if (_toDropoff) {
                              topCta = ElevatedButton(
                                onPressed: (_completeInProgress ||
                                        sessionState is! AuthSessionAuthenticated)
                                    ? null
                                    : () async {
                                        setState(() => _completeInProgress = true);
                                        try {
                                          final riderId = sessionState.user.uid;
                                          await context
                                              .read<RideRepository>()
                                              .completeDropoff(
                                                rideId: widget.rideId,
                                                riderId: riderId,
                                              );
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          setState(() => _completeInProgress = false);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString())),
                                          );
                                        }
                                      },
                                child: _completeInProgress
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Complete Dropoff'),
                              );
                            } else {
                              topCta = const ElevatedButton(
                                onPressed: null,
                                child: Text('Pickup Complete'),
                              );
                            }
                          } else if (status == 'arrived_pickup') {
                            if (otp == null || otp.trim().isEmpty) {
                              topCta = const ElevatedButton(
                                onPressed: null,
                                child: Text('Waiting for OTP…'),
                              );
                            } else {
                              topCta = ElevatedButton(
                                onPressed: _showPickupOtpDialog,
                                child: const Text('Verify Pickup OTP'),
                              );
                            }
                          } else {
                            topCta = ElevatedButton(
                              onPressed: () async {
                                try {
                                  await context
                                      .read<RideRepository>()
                                      .markArrivedAtPickup(rideId: widget.rideId);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Arrived at pickup. Waiting for OTP…'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                }
                              },
                              child: const Text('Reached Pickup Location'),
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
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: canNavigateDropoff
                                          ? () {
                                              if (!_toDropoff) {
                                                _switchToDropoffIfNeeded();
                                              }
                                              _openGoogleMaps(origin: origin);
                                            }
                                          : null,
                                      child: const Text('Navigate to Dropoff'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                        foregroundColor:
                                            Theme.of(context).colorScheme.onError,
                                      ),
                                      onPressed: (_cancelInProgress ||
                                              sessionState is! AuthSessionAuthenticated)
                                          ? null
                                          : () async {
                                              setState(() => _cancelInProgress = true);
                                              try {
                                                final riderId = sessionState.user.uid;
                                                await context
                                                    .read<RideRepository>()
                                                    .cancelRide(
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
                                                  ),
                                                );
                                              }
                                            },
                                      child: _cancelInProgress
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('Cancel Ride'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
    return AlertDialog(
      title: const Text('Enter Pickup OTP'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 4,
        decoration: InputDecoration(
          labelText: '4-digit OTP',
          errorText: _errorText,
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
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
