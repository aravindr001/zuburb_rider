import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/rider_design_tokens.dart';

/// Floating request card shown at the bottom of the screen
/// when a ride request comes in. Includes customer info,
/// trip details, pickup map preview, accept/decline buttons,
/// countdown timer, and surge pricing indicator.
class IncomingRequestCard extends StatefulWidget {
  /// Customer name
  final String customerName;

  /// Customer rating (e.g. 4.8)
  final double customerRating;

  /// Number of trips the customer has taken
  final int customerTrips;

  /// Customer photo URL (optional)
  final String? customerPhotoUrl;

  /// Pickup address string
  final String pickupAddress;

  /// Dropoff address string
  final String dropoffAddress;

  /// Trip distance in km
  final double distanceKm;

  /// Estimated fare in dollars
  final double estimatedFare;

  /// Estimated trip duration in minutes
  final int estimatedDurationMinutes;

  /// Countdown timer in seconds before auto-decline
  final int countdownSeconds;

  /// Whether surge pricing is active
  final bool hasSurge;

  /// Surge multiplier if applicable (e.g. 1.5)
  final double? surgeMultiplier;

  /// Pickup latitude (for map preview)
  final double pickupLat;

  /// Pickup longitude (for map preview)
  final double pickupLng;

  /// Called when the rider accepts the request
  final VoidCallback onAccept;

  /// Called when the rider declines the request
  final VoidCallback onDecline;

  /// Called when the countdown timer expires (auto-decline)
  final VoidCallback? onTimerExpired;

  const IncomingRequestCard({
    super.key,
    required this.customerName,
    required this.customerRating,
    required this.customerTrips,
    this.customerPhotoUrl,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.estimatedFare,
    required this.estimatedDurationMinutes,
    required this.countdownSeconds,
    this.hasSurge = false,
    this.surgeMultiplier,
    required this.pickupLat,
    required this.pickupLng,
    required this.onAccept,
    required this.onDecline,
    this.onTimerExpired,
  });

  @override
  State<IncomingRequestCard> createState() => _IncomingRequestCardState();
}

class _IncomingRequestCardState extends State<IncomingRequestCard>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _slideController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onTimerExpired?.call();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (_remainingSeconds > 20) return RiderDesignTokens.textSecondary;
    if (_remainingSeconds > 10) return RiderDesignTokens.warning;
    return RiderDesignTokens.error;
  }

  String get _timerText {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Card takes up bottom ~60% of screen
    final cardHeight = screenHeight * 0.62;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x60000000),
                  blurRadius: 32,
                  offset: Offset(0, -8),
                ),
              ],
              border: const Border(
                top: BorderSide(color: RiderDesignTokens.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // ── Drag handle ─────────────────────────────────
                _buildDragHandle(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RiderDesignTokens.spacing20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Countdown + Surge ─────────────────────
                        _buildCountdownAndSurge(),

                        const SizedBox(height: RiderDesignTokens.spacing16),

                        // ── Customer Info ────────────────────────
                        _buildCustomerInfo(),

                        const SizedBox(height: RiderDesignTokens.spacing16),

                        // ── Trip Details ─────────────────────────
                        _buildTripDetails(),

                        const SizedBox(height: RiderDesignTokens.spacing16),

                        // ── Route Preview ─────────────────────────
                        _buildRoutePreview(),

                        const SizedBox(height: RiderDesignTokens.spacing20),

                        // ── Action Buttons ───────────────────────
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            color: RiderDesignTokens.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownAndSurge() {
    return Row(
      children: [
        // Countdown badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _timerColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
            border: Border.all(
              color: _timerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, color: _timerColor, size: 16),
              const SizedBox(width: 6),
              Text(
                _timerText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _timerColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        if (widget.hasSurge) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: RiderDesignTokens.surge.withOpacity(0.15),
              borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
              border: Border.all(
                color: RiderDesignTokens.surge.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    color: RiderDesignTokens.surge, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.surgeMultiplier != null
                      ? '${widget.surgeMultiplier}x SURGE'
                      : 'SURGE',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: RiderDesignTokens.surge,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // "New Ride" label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: RiderDesignTokens.brand.withOpacity(0.12),
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
          ),
          child: const Text(
            'NEW RIDE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: RiderDesignTokens.brand,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Row(
        children: [
          // Customer avatar
          _CustomerAvatar(
            name: widget.customerName,
            photoUrl: widget.customerPhotoUrl,
            size: 52,
          ),
          const SizedBox(width: RiderDesignTokens.spacing14),
          // Customer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerName,
                  style: const TextStyle(
                    fontSize: 17,
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
                      widget.customerRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: RiderDesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: RiderDesignTokens.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.customerTrips} trips',
                      style: const TextStyle(
                        fontSize: 13,
                        color: RiderDesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RiderDesignTokens.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
              border: Border.all(
                color: RiderDesignTokens.success.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.call,
              color: RiderDesignTokens.success,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails() {
    final _ = widget.hasSurge && widget.surgeMultiplier != null
        ? '\$${(widget.estimatedFare * widget.surgeMultiplier!).toStringAsFixed(2)}'
        : '\$${widget.estimatedFare.toStringAsFixed(2)}';

    return Row(
      children: [
        // Pickup
        Expanded(
          child: _LocationCard(
            label: 'PICKUP',
            address: widget.pickupAddress,
            icon: Icons.trip_origin,
            iconColor: RiderDesignTokens.statePickup,
          ),
        ),
        const SizedBox(width: RiderDesignTokens.spacing10),
        // Dropoff
        Expanded(
          child: _LocationCard(
            label: 'DROPOFF',
            address: widget.dropoffAddress,
            icon: Icons.location_on,
            iconColor: RiderDesignTokens.error,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePreview() {
    final fareText = widget.hasSurge && widget.surgeMultiplier != null
        ? '\$${(widget.estimatedFare * widget.surgeMultiplier!).toStringAsFixed(2)}'
        : '\$${widget.estimatedFare.toStringAsFixed(2)}';

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Row(
        children: [
          // Map placeholder (integrate with Google Maps widget)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(RiderDesignTokens.radius12),
                ),
                color: RiderDesignTokens.surface,
              ),
              child: Stack(
                children: [
                  // Map preview placeholder — replace with Google Maps widget
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          color: RiderDesignTokens.textTertiary,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            color: RiderDesignTokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Trip stats
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(RiderDesignTokens.spacing12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TripStat(
                    icon: Icons.route,
                    value: '${widget.distanceKm.toStringAsFixed(1)} km',
                    label: 'Distance',
                  ),
                  const SizedBox(height: 8),
                  _TripStat(
                    icon: Icons.schedule,
                    value: '${widget.estimatedDurationMinutes} min',
                    label: 'Duration',
                  ),
                ],
              ),
            ),
          ),
          // Fare
          Container(
            padding: const EdgeInsets.all(RiderDesignTokens.spacing12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: RiderDesignTokens.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fareText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: widget.hasSurge
                        ? RiderDesignTokens.surge
                        : RiderDesignTokens.brand,
                  ),
                ),
                const Text(
                  'Est. Fare',
                  style: TextStyle(
                    fontSize: 10,
                    color: RiderDesignTokens.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttonHeight = MediaQuery.of(context).size.height * 0.09;
    final minButtonHeight = 64.0;

    return Column(
      children: [
        // DECLINE button
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: RiderDesignTokens.error,
              side: const BorderSide(color: RiderDesignTokens.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'DECLINE',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: RiderDesignTokens.spacing12),
        // ACCEPT button — bottom 40% of card area, prominent
        SizedBox(
          height: buttonHeight.clamp(minButtonHeight, 72),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: RiderDesignTokens.brand,
              foregroundColor: RiderDesignTokens.textOnBrand,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 24),
                SizedBox(width: 10),
                Text(
                  'ACCEPT RIDE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RiderDesignTokens.spacing8),
      ],
    );
  }
}

// ── Customer Avatar ──────────────────────────────────────────────────────────

class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;

  const _CustomerAvatar({
    required this.name,
    this.photoUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
        ),
      );
    }
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A3AFF), Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Location Card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final String label;
  final String address;
  final IconData icon;
  final Color iconColor;

  const _LocationCard({
    required this.label,
    required this.address,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing12),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: RiderDesignTokens.textTertiary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            address,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: RiderDesignTokens.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Trip Stat ───────────────────────────────────────────────────────────────

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TripStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: RiderDesignTokens.textTertiary, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
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
      ],
    );
  }
}