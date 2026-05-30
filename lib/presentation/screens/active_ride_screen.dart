import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/rider_design_tokens.dart';

/// Active ride screen with a visually distinct 5-state machine.
/// Each state has its own color accent, icon, and layout.
/// State transitions are animated.
class ActiveRideScreen extends StatefulWidget {
  /// The current ride state
  final RideState initialState;

  /// Customer name
  final String customerName;

  /// Customer photo URL (optional)
  final String? customerPhotoUrl;

  /// Customer rating
  final double customerRating;

  /// Customer phone number (for calling)
  final String? customerPhone;

  /// Pickup address string
  final String pickupAddress;

  /// Dropoff address string
  final String dropoffAddress;

  /// OTP for pickup verification (partially masked in UI)
  final String? pickupOtp;

  /// Estimated pickup distance in km
  final double pickupDistanceKm;

  /// Estimated pickup ETA in minutes
  final int pickupEtaMinutes;

  /// Estimated drop-off distance in km
  final double dropDistanceKm;

  /// Estimated drop-off ETA in minutes
  final int dropEtaMinutes;

  /// Pickup coordinates
  final double pickupLat;
  final double pickupLng;

  /// Dropoff coordinates
  final double dropLat;
  final double dropLng;

  /// Trip fare
  final double fare;

  /// Trip distance
  final double tripDistanceKm;

  /// Trip duration
  final int tripDurationMinutes;

  /// Callback when rider marks arrived at pickup
  final VoidCallback? onArrivedAtPickup;

  /// Callback when OTP is verified
  final VoidCallback? onOtpVerified;

  /// Callback when rider confirms customer picked up
  final VoidCallback? onCustomerPickedUp;

  /// Callback when rider completes dropoff
  final VoidCallback? onDropoffComplete;

  /// Callback when ride is cancelled
  final VoidCallback? onRideCancelled;

  /// Callback when rider calls customer
  final VoidCallback? onCallCustomer;

  const ActiveRideScreen({
    super.key,
    required this.initialState,
    required this.customerName,
    this.customerPhotoUrl,
    required this.customerRating,
    this.customerPhone,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.pickupOtp,
    required this.pickupDistanceKm,
    required this.pickupEtaMinutes,
    required this.dropDistanceKm,
    required this.dropEtaMinutes,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.fare,
    required this.tripDistanceKm,
    required this.tripDurationMinutes,
    this.onArrivedAtPickup,
    this.onOtpVerified,
    this.onCustomerPickedUp,
    this.onDropoffComplete,
    this.onRideCancelled,
    this.onCallCustomer,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with TickerProviderStateMixin {
  late RideState _currentState;
  late AnimationController _stateTransitionController;
  late Animation<double> _stateAnimation;

  // OTP input
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _otpVerified = false;
  bool _otpError = false;
  bool _isVerifying = false;

  // Other state
  bool _arrivedAtPickup = false;
  bool _isNavigating = false;
  bool _isCancelling = false;
  bool _isCompleting = false;

  GoogleMapController? _mapController;
  bool _cameraFittedOnce = false;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
    _stateTransitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _stateAnimation = CurvedAnimation(
      parent: _stateTransitionController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _stateTransitionController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _transitionToState(RideState newState) {
    if (newState == _currentState) return;
    _stateTransitionController.reverse().then((_) {
      setState(() => _currentState = newState);
      _stateTransitionController.forward();
    });
  }

  Future<void> _openGoogleMaps({bool toDropoff = false}) async {
    final lat = toDropoff ? widget.dropLat : widget.pickupLat;
    final lng = toDropoff ? widget.dropLng : widget.pickupLng;
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {'api': '1', 'travelmode': 'driving', 'destination': '$lat,$lng'},
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _fitCameraForRoute() {
    if (_mapController == null || _cameraFittedOnce) return;
    _cameraFittedOnce = true;
    final sw = LatLng(
      widget.pickupLat < widget.dropLat ? widget.pickupLat : widget.dropLat,
      widget.pickupLng < widget.dropLng ? widget.pickupLng : widget.dropLng,
    );
    final ne = LatLng(
      widget.pickupLat > widget.dropLat ? widget.pickupLat : widget.dropLat,
      widget.pickupLng > widget.dropLng ? widget.pickupLng : widget.dropLng,
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = RiderDesignTokens.colorForState(_currentState);
    final stateIcon = RiderDesignTokens.iconForState(_currentState);
    final stateLabel = RiderDesignTokens.labelForState(_currentState);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: RiderDesignTokens.background,
        body: Stack(
          children: [
            // ── Map (full screen background) ──────────────────────
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.pickupLat, widget.pickupLng),
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitCameraForRoute();
              },
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(widget.pickupLat, widget.pickupLng),
                  infoWindow: const InfoWindow(title: 'Pickup'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: LatLng(widget.dropLat, widget.dropLng),
                  infoWindow: const InfoWindow(title: 'Dropoff'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              },
            ),

            // ── State Header Banner ────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _StateHeader(
                state: _currentState,
                accentColor: accentColor,
                stateIcon: stateIcon,
                stateLabel: stateLabel,
                customerName: widget.customerName,
                fare: widget.fare,
                onClose: widget.onRideCancelled != null
                    ? () => _showCancelDialog(context)
                    : null,
              ),
            ),

            // ── Earnings HUD (always visible top-right) ───────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              right: 16,
              child: _EarningsHud(
                fare: widget.fare,
                accentColor: accentColor,
              ),
            ),

            // ── Bottom Sheet (state-specific UI) ───────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _stateAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(_stateAnimation),
                  child: _StateBottomSheet(
                    state: _currentState,
                    accentColor: accentColor,
                    stateIcon: stateIcon,
                    stateLabel: stateLabel,
                    widget: widget,
                    otpControllers: _otpControllers,
                    otpFocusNodes: _otpFocusNodes,
                    otpVerified: _otpVerified,
                    otpError: _otpError,
                    isVerifying: _isVerifying,
                    arrivedAtPickup: _arrivedAtPickup,
                    isCancelling: _isCancelling,
                    isCompleting: _isCompleting,
                    onArrivedAtPickup: () {
                      setState(() => _arrivedAtPickup = true);
                      widget.onArrivedAtPickup?.call();
                      _transitionToState(RideState.otpVerify);
                    },
                    onOtpChange: (index, value) {
                      setState(() => _otpError = false);
                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      }
                    },
                    onOtpSubmit: _handleOtpSubmit,
                    onCustomerPickedUp: () {
                      widget.onCustomerPickedUp?.call();
                      _transitionToState(RideState.pickup);
                    },
                    onDropoffComplete: () async {
                      setState(() => _isCompleting = true);
                      widget.onDropoffComplete?.call();
                      if (mounted) {
                        setState(() => _isCompleting = false);
                        _transitionToState(RideState.complete);
                      }
                    },
                    onCancel: () => _showCancelDialog(context),
                    onCallCustomer: widget.onCallCustomer,
                    onNavigate: () => _openGoogleMaps(
                      toDropoff: _currentState == RideState.pickup,
                    ),
                    onUpdateEta: () {
                      // Placeholder — refresh ETA from server
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ETA updated')),
                      );
                    },
                    onResendOtp: _handleResendOtp,
                  ),
                ),
              ),
            ),

            // ── SOS Button (always visible) ────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.58 + 16,
              right: 16,
              child: _SosButton(onTap: () => _showSosDialog(context)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOtpSubmit() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _otpError = true);
      return;
    }

    setState(() => _isVerifying = true);
    // Simulate verification — replace with actual verification call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (otp == widget.pickupOtp || widget.pickupOtp == null) {
      setState(() {
        _otpVerified = true;
        _isVerifying = false;
      });
      widget.onOtpVerified?.call();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _transitionToState(RideState.pickup);
      }
    } else {
      setState(() {
        _otpError = true;
        _isVerifying = false;
      });
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
    }
  }

  void _handleResendOtp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent to customer')),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RiderDesignTokens.surfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: RiderDesignTokens.error, size: 24),
            SizedBox(width: 12),
            Text('Cancel Ride?', style: TextStyle(color: RiderDesignTokens.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this ride? This may affect your acceptance rate.',
          style: TextStyle(color: RiderDesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Continue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderDesignTokens.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onRideCancelled?.call();
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RiderDesignTokens.surfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.sos, color: RiderDesignTokens.error, size: 28),
            SizedBox(width: 12),
            Text('Emergency SOS', style: TextStyle(color: RiderDesignTokens.textPrimary)),
          ],
        ),
        content: const Text(
          'This will alert emergency contacts and support.',
          style: TextStyle(color: RiderDesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderDesignTokens.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOS alert sent')),
              );
            },
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );
  }
}

// ── State Header ────────────────────────────────────────────────────────────

class _StateHeader extends StatelessWidget {
  final RideState state;
  final Color accentColor;
  final IconData stateIcon;
  final String stateLabel;
  final String customerName;
  final double fare;
  final VoidCallback? onClose;

  const _StateHeader({
    required this.state,
    required this.accentColor,
    required this.stateIcon,
    required this.stateLabel,
    required this.customerName,
    required this.fare,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 8,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          // State badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stateIcon, color: accentColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  stateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Customer name
          Expanded(
            child: Text(
              customerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: RiderDesignTokens.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Fare
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: RiderDesignTokens.brand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(RiderDesignTokens.radius8),
            ),
            child: Text(
              '\$${fare.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RiderDesignTokens.brand,
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: RiderDesignTokens.textSecondary, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Earnings HUD ─────────────────────────────────────────────────────────────

class _EarningsHud extends StatelessWidget {
  final double fare;
  final Color accentColor;

  const _EarningsHud({required this.fare, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceElevated.withOpacity(0.9),
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: accentColor, size: 18),
          const SizedBox(width: 8),
          Text(
            '\$${fare.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SOS Button ────────────────────────────────────────────────────────────────

class _SosButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SosButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: RiderDesignTokens.error.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: RiderDesignTokens.error.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.sos,
          color: RiderDesignTokens.error,
          size: 24,
        ),
      ),
    );
  }
}

// ── State Bottom Sheet (renders based on state) ─────────────────────────────

class _StateBottomSheet extends StatelessWidget {
  final RideState state;
  final Color accentColor;
  final IconData stateIcon;
  final String stateLabel;
  final ActiveRideScreen widget;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool otpVerified;
  final bool otpError;
  final bool isVerifying;
  final bool arrivedAtPickup;
  final bool isCancelling;
  final bool isCompleting;
  final VoidCallback onArrivedAtPickup;
  final void Function(int index, String value) onOtpChange;
  final VoidCallback onOtpSubmit;
  final VoidCallback onCustomerPickedUp;
  final VoidCallback onDropoffComplete;
  final VoidCallback onCancel;
  final VoidCallback? onCallCustomer;
  final VoidCallback onNavigate;
  final VoidCallback onUpdateEta;
  final VoidCallback onResendOtp;

  const _StateBottomSheet({
    required this.state,
    required this.accentColor,
    required this.stateIcon,
    required this.stateLabel,
    required this.widget,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.otpVerified,
    required this.otpError,
    required this.isVerifying,
    required this.arrivedAtPickup,
    required this.isCancelling,
    required this.isCompleting,
    required this.onArrivedAtPickup,
    required this.onOtpChange,
    required this.onOtpSubmit,
    required this.onCustomerPickedUp,
    required this.onDropoffComplete,
    required this.onCancel,
    this.onCallCustomer,
    required this.onNavigate,
    required this.onUpdateEta,
    required this.onResendOtp,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.42;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            RiderDesignTokens.surfaceElevated,
            RiderDesignTokens.surface,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RiderDesignTokens.radius28),
        ),
        border: const Border(
          top: BorderSide(color: RiderDesignTokens.border, width: 1),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x60000000), blurRadius: 32, offset: Offset(0, -8)),
        ],
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: RiderDesignTokens.spacing20,
              ),
              child: switch (state) {
                RideState.accepted => _buildAcceptedState(context),
                RideState.navigate => _buildNavigateState(context),
                RideState.otpVerify => _buildOtpVerifyState(context),
                RideState.pickup => _buildPickupState(context),
                RideState.complete => _buildCompleteState(context),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ── a) ACCEPTED state ─────────────────────────────────────────────

  Widget _buildAcceptedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer info
        _StateCustomerCard(
          customerName: widget.customerName,
          customerPhotoUrl: widget.customerPhotoUrl,
          customerRating: widget.customerRating,
          accentColor: accentColor,
          onCall: onCallCustomer,
        ),
        const SizedBox(height: RiderDesignTokens.spacing16),

        // Route info
        _RouteInfoCard(
          pickupAddress: widget.pickupAddress,
          dropAddress: widget.dropoffAddress,
          pickupDistanceKm: widget.pickupDistanceKm,
          pickupEtaMinutes: widget.pickupEtaMinutes,
          accentColor: accentColor,
        ),

        const SizedBox(height: RiderDesignTokens.spacing16),

        // OTP display
        if (widget.pickupOtp != null) _OtpDisplayCard(otp: widget.pickupOtp!),

        const SizedBox(height: RiderDesignTokens.spacing20),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.navigation,
                label: 'Navigate',
                onPressed: onNavigate,
              ),
            ),
            const SizedBox(width: RiderDesignTokens.spacing12),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.call,
                label: 'Call',
                onPressed: onCallCustomer ?? () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _PrimaryButton(
                icon: Icons.check_circle,
                label: 'Arrived',
                color: accentColor,
                onPressed: onArrivedAtPickup,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DangerButton(
                label: 'Cancel',
                onPressed: onCancel,
                isLoading: isCancelling,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── b) NAVIGATE state ────────────────────────────────────────────

  Widget _buildNavigateState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Turn-by-turn direction card
        _NavigationDirectionCard(
          distanceKm: widget.pickupDistanceKm,
          etaMinutes: widget.pickupEtaMinutes,
          destination: widget.pickupAddress,
          accentColor: accentColor,
        ),
        const SizedBox(height: RiderDesignTokens.spacing16),

        // Trip info row
        Row(
          children: [
            Expanded(
              child: _InfoPill(
                icon: Icons.social_distance,
                label: '${widget.pickupDistanceKm.toStringAsFixed(1)} km',
                sublabel: 'to pickup',
                color: accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoPill(
                icon: Icons.schedule,
                label: '$widget.pickupEtaMinutes min',
                sublabel: 'ETA',
                color: RiderDesignTokens.stateNavigate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoPill(
                icon: Icons.account_balance_wallet,
                label: '\$${widget.fare.toStringAsFixed(2)}',
                sublabel: 'fare',
                color: RiderDesignTokens.brand,
              ),
            ),
          ],
        ),

        const SizedBox(height: RiderDesignTokens.spacing20),

        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                icon: Icons.navigation,
                label: 'Google Maps',
                onPressed: onNavigate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SecondaryButton(
                icon: Icons.refresh,
                label: 'Update ETA',
                onPressed: onUpdateEta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (onCallCustomer != null)
          _SecondaryButton(
            icon: Icons.call,
            label: 'Contact Customer',
            onPressed: onCallCustomer ?? () {},
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── c) OTP_VERIFY state ───────────────────────────────────────────

  Widget _buildOtpVerifyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verification header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (otpVerified ? RiderDesignTokens.success : accentColor)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
              ),
              child: Icon(
                otpVerified ? Icons.check_circle : Icons.pin_invoke,
                color: otpVerified ? RiderDesignTokens.success : accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otpVerified ? 'OTP Verified!' : 'Verify Pickup OTP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: otpVerified
                          ? RiderDesignTokens.success
                          : RiderDesignTokens.textPrimary,
                    ),
                  ),
                  Text(
                    otpVerified
                        ? 'Customer has been confirmed'
                        : 'Enter the 6-digit OTP from the customer',
                    style: const TextStyle(
                      fontSize: 13,
                      color: RiderDesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (!otpVerified) ...[
          const SizedBox(height: RiderDesignTokens.spacing20),

          // Large OTP input
          _LargeOtpInput(
            controllers: otpControllers,
            focusNodes: otpFocusNodes,
            hasError: otpError,
            onChange: onOtpChange,
            accentColor: accentColor,
          ),

          const SizedBox(height: 12),

          // Resend OTP
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onResendOtp,
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Verify button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isVerifying ? null : onOtpSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accentColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
                ),
              ),
              child: isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'VERIFY OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Manual override
          Center(
            child: TextButton(
              onPressed: () => _showManualOverrideDialog(context),
              child: const Text(
                'Manual Override',
                style: TextStyle(
                  color: RiderDesignTokens.textTertiary,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],

        if (otpVerified) ...[
          const SizedBox(height: RiderDesignTokens.spacing20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onCustomerPickedUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderDesignTokens.statePickup,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_alt, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'CUSTOMER PICKED UP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _showManualOverrideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RiderDesignTokens.surfaceElevated,
        title: const Text('Manual Override',
            style: TextStyle(color: RiderDesignTokens.textPrimary)),
        content: const Text(
          'This should only be used if the customer cannot provide the OTP. '
          'This action will be logged.',
          style: TextStyle(color: RiderDesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCustomerPickedUp();
            },
            child: const Text('Confirm Override'),
          ),
        ],
      ),
    );
  }

  // ── d) PICKUP state ──────────────────────────────────────────────

  Widget _buildPickupState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer picked up banner
        Container(
          padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
          decoration: BoxDecoration(
            color: RiderDesignTokens.statePickup.withOpacity(0.12),
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
            border: Border.all(
              color: RiderDesignTokens.statePickup.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: RiderDesignTokens.statePickup, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Picked Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: RiderDesignTokens.statePickup,
                      ),
                    ),
                    Text(
                      'Trip to destination has started',
                      style: TextStyle(
                        fontSize: 12,
                        color: RiderDesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: RiderDesignTokens.spacing16),

        // Destination card
        _DestinationCard(
          address: widget.dropoffAddress,
          distanceKm: widget.dropDistanceKm,
          etaMinutes: widget.dropEtaMinutes,
          accentColor: accentColor,
        ),

        const SizedBox(height: RiderDesignTokens.spacing16),

        // Trip stats
        Row(
          children: [
            _StatCard(
              icon: Icons.route,
              label: 'Distance',
              value: '${widget.tripDistanceKm.toStringAsFixed(1)} km',
              color: accentColor,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.schedule,
              label: 'Duration',
              value: '${widget.tripDurationMinutes} min',
              color: accentColor,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.account_balance_wallet,
              label: 'Fare',
              value: '\$${widget.fare.toStringAsFixed(2)}',
              color: RiderDesignTokens.brand,
            ),
          ],
        ),

        const SizedBox(height: RiderDesignTokens.spacing20),

        // Navigate to dropoff
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onNavigate,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation, size: 22),
                SizedBox(width: 8),
                Text(
                  'NAVIGATE TO DROPOFF',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Complete dropoff
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isCompleting ? null : onDropoffComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderDesignTokens.brand,
              foregroundColor: RiderDesignTokens.textOnBrand,
              disabledBackgroundColor: RiderDesignTokens.brand.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
              ),
            ),
            child: isCompleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'COMPLETE DROPOFF',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── e) COMPLETE state ─────────────────────────────────────────────

  Widget _buildCompleteState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(RiderDesignTokens.spacing20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                RiderDesignTokens.brand.withOpacity(0.15),
                RiderDesignTokens.stateComplete.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius20),
            border: Border.all(
              color: RiderDesignTokens.brand.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: RiderDesignTokens.brand.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flag,
                  color: RiderDesignTokens.brand,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ride Complete!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: RiderDesignTokens.brand,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Great job, Rider',
                style: TextStyle(
                  fontSize: 14,
                  color: RiderDesignTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: RiderDesignTokens.spacing20),

        // Earnings breakdown
        _EarningsBreakdownCard(fare: widget.fare),

        const SizedBox(height: RiderDesignTokens.spacing16),

        // Trip summary
        _TripSummaryCard(
          distanceKm: widget.tripDistanceKm,
          durationMinutes: widget.tripDurationMinutes,
          pickupAddress: widget.pickupAddress,
          dropoffAddress: widget.dropoffAddress,
        ),

        const SizedBox(height: RiderDesignTokens.spacing20),

        // Customer rating (if available)
        // Placeholder for customer rating display

        const SizedBox(height: 12),

        // Next ride prompt
        Container(
          padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
          decoration: BoxDecoration(
            color: RiderDesignTokens.surface,
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
            border: Border.all(color: RiderDesignTokens.border, width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: RiderDesignTokens.brand, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Looking for your next ride?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: RiderDesignTokens.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: RiderDesignTokens.textTertiary, size: 14),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── State: Customer Card ─────────────────────────────────────────────────────

class _StateCustomerCard extends StatelessWidget {
  final String customerName;
  final String? customerPhotoUrl;
  final double customerRating;
  final Color accentColor;
  final VoidCallback? onCall;

  const _StateCustomerCard({
    required this.customerName,
    this.customerPhotoUrl,
    required this.customerRating,
    required this.accentColor,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withOpacity(0.6), accentColor],
              ),
              borderRadius: BorderRadius.circular(RiderDesignTokens.radius14),
            ),
            child: Center(
              child: Text(
                customerName.isNotEmpty
                    ? customerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: RiderDesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      customerRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RiderDesignTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onCall != null)
            GestureDetector(
              onTap: onCall,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
                  border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
                ),
                child: Icon(Icons.call, color: accentColor, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

// ── State: Route Info Card ───────────────────────────────────────────────────

class _RouteInfoCard extends StatelessWidget {
  final String pickupAddress;
  final String dropAddress;
  final double pickupDistanceKm;
  final int pickupEtaMinutes;
  final Color accentColor;

  const _RouteInfoCard({
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupDistanceKm,
    required this.pickupEtaMinutes,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Column(
        children: [
          // Pickup
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: RiderDesignTokens.statePickup,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICKUP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: RiderDesignTokens.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      pickupAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: RiderDesignTokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Dashed line
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 24,
                  color: RiderDesignTokens.border,
                ),
              ],
            ),
          ),
          // Dropoff
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: RiderDesignTokens.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROPOFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: RiderDesignTokens.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      dropAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: RiderDesignTokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Distance and ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.social_distance, color: accentColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${pickupDistanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RiderDesignTokens.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.schedule, color: accentColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$pickupEtaMinutes min',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: RiderDesignTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── State: OTP Display Card ─────────────────────────────────────────────────

class _OtpDisplayCard extends StatelessWidget {
  final String otp;
  const _OtpDisplayCard({required this.otp});

  @override
  Widget build(BuildContext context) {
    // Mask OTP — show first 2 and last 1 digits
    final masked = otp.length >= 3
        ? '${otp[0]}${otp[1]} • • • ${otp[otp.length - 1]}'
        : otp;

    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(
          color: RiderDesignTokens.stateOtp.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RiderDesignTokens.stateOtp.withOpacity(0.15),
              borderRadius: BorderRadius.circular(RiderDesignTokens.radius10),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: RiderDesignTokens.stateOtp,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PICKUP OTP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: RiderDesignTokens.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              Text(
                masked,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: RiderDesignTokens.stateOtp,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Show to customer',
            style: TextStyle(
              fontSize: 11,
              color: RiderDesignTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── State: Navigation Direction Card ────────────────────────────────────────

class _NavigationDirectionCard extends StatelessWidget {
  final double distanceKm;
  final int etaMinutes;
  final String destination;
  final Color accentColor;

  const _NavigationDirectionCard({
    required this.distanceKm,
    required this.etaMinutes,
    required this.destination,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing20),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Direction icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.navigation,
              color: accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$etaMinutes min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'to pickup',
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor.withOpacity(0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: RiderDesignTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── State: Large OTP Input ──────────────────────────────────────────────────

class _LargeOtpInput extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final void Function(int index, String value) onChange;
  final Color accentColor;

  const _LargeOtpInput({
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.onChange,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 48,
                height: 60,
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: hasError ? RiderDesignTokens.error : accentColor,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: hasError
                        ? RiderDesignTokens.error.withOpacity(0.08)
                        : accentColor.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? RiderDesignTokens.error
                            : accentColor.withOpacity(0.3),
                        width: hasError ? 2 : 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? RiderDesignTokens.error
                            : accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasError
                            ? RiderDesignTokens.error
                            : accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => onChange(index, value),
                ),
              ),
            );
          }),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: const Text(
              'Invalid OTP. Please try again.',
              style: TextStyle(
                fontSize: 13,
                color: RiderDesignTokens.error,
              ),
            ),
          ),
      ],
    );
  }
}

// ── State: Destination Card ─────────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final String address;
  final double distanceKm;
  final int etaMinutes;
  final Color accentColor;

  const _DestinationCard({
    required this.address,
    required this.distanceKm,
    required this.etaMinutes,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: accentColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'DROPOFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: RiderDesignTokens.textTertiary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: RiderDesignTokens.textPrimary,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(label: 'Distance', value: '${distanceKm.toStringAsFixed(1)} km'),
              const SizedBox(width: 20),
              _MiniStat(label: 'ETA', value: '$etaMinutes min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: RiderDesignTokens.textTertiary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: RiderDesignTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── State: Stat Card ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(RiderDesignTokens.spacing12),
        decoration: BoxDecoration(
          color: RiderDesignTokens.surface,
          borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
          border: Border.all(color: RiderDesignTokens.border, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: RiderDesignTokens.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: RiderDesignTokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── State: Earnings Breakdown Card ──────────────────────────────────────────

class _EarningsBreakdownCard extends StatelessWidget {
  final double fare;
  const _EarningsBreakdownCard({required this.fare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing20),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surface,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Base Fare', style: TextStyle(color: RiderDesignTokens.textSecondary)),
              Text('\$5.00', style: TextStyle(color: RiderDesignTokens.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance', style: TextStyle(color: RiderDesignTokens.textSecondary)),
              Text('\$3.50', style: TextStyle(color: RiderDesignTokens.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time', style: TextStyle(color: RiderDesignTokens.textSecondary)),
              Text('\$2.00', style: TextStyle(color: RiderDesignTokens.textPrimary)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: RiderDesignTokens.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Earned',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: RiderDesignTokens.brand,
                ),
              ),
              Text(
                '\$${fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: RiderDesignTokens.brand,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── State: Trip Summary Card ────────────────────────────────────────────────

class _TripSummaryCard extends StatelessWidget {
  final double distanceKm;
  final int durationMinutes;
  final String pickupAddress;
  final String dropoffAddress;

  const _TripSummaryCard({
    required this.distanceKm,
    required this.durationMinutes,
    required this.pickupAddress,
    required this.dropoffAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryDot(color: RiderDesignTokens.statePickup),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(
                        fontSize: 10,
                        color: RiderDesignTokens.textTertiary,
                      ),
                    ),
                    Text(
                      pickupAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RiderDesignTokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SummaryDot(color: RiderDesignTokens.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(
                        fontSize: 10,
                        color: RiderDesignTokens.textTertiary,
                      ),
                    ),
                    Text(
                      dropoffAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: RiderDesignTokens.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryStat(label: 'Distance', value: '${distanceKm.toStringAsFixed(1)} km'),
              Container(width: 1, height: 24, color: RiderDesignTokens.border),
              _SummaryStat(label: 'Duration', value: '$durationMinutes min'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryDot extends StatelessWidget {
  final Color color;
  const _SummaryDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: RiderDesignTokens.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: RiderDesignTokens.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ── State: Info Pill ────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 10,
              color: RiderDesignTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: RiderDesignTokens.textPrimary,
          side: const BorderSide(color: RiderDesignTokens.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: RiderDesignTokens.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RiderDesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _DangerButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: RiderDesignTokens.error,
          side: const BorderSide(color: RiderDesignTokens.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: RiderDesignTokens.error),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}