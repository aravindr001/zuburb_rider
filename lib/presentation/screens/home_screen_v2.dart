import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';


import '../../bloc/rider_online/rider_online_cubit.dart';
import '../../bloc/scheduled_rides/scheduled_rides_cubit.dart';
import '../../bloc/scheduled_rides/scheduled_rides_state.dart';
import '../../bloc/session/auth_session_cubit.dart';
import '../../bloc/session/auth_session_state.dart';
import '../../theme/rider_design_tokens.dart';

import 'scheduled_rides_screen.dart';
import 'rider_availability_screen.dart';

/// Premium dark-first home screen v2 for the rider app.
/// Features a large online/offline toggle, earnings summary,
/// and quick action buttons.
class RiderHomeScreenV2 extends StatelessWidget {
  const RiderHomeScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<AuthSessionCubit>().state;
    if (sessionState is! AuthSessionAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RiderOnlineCubit(
            context.read(),
            sessionState.user.uid,
          ),
        ),
        BlocProvider(
          create: (context) => ScheduledRidesCubit(
            context.read(),
            context.read(),
            sessionState.user.uid,
          ),
        ),
      ],
      child: _RiderHomeV2View(riderId: sessionState.user.uid),
    );
  }
}

class _RiderHomeV2View extends StatefulWidget {
  final String riderId;
  const _RiderHomeV2View({required this.riderId});

  @override
  State<_RiderHomeV2View> createState() => _RiderHomeV2ViewState();
}

class _RiderHomeV2ViewState extends State<_RiderHomeV2View>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleOnlineToggle(bool value) async {
    if (value) {
      // Check location services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permission is required.');
        return;
      }
    }

    await context.read<RiderOnlineCubit>().setOnline(value);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderDesignTokens.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RiderDesignTokens.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────────
              _TopBar(riderId: widget.riderId),

              // ── Rider Profile Summary ────────────────────────────
              const _RiderProfileCard(),

              // ── Earnings Summary ────────────────────────────────
              const _EarningsSummary(),

              const Spacer(),

              // ── Online / Offline Toggle ────────────────────────
              BlocBuilder<RiderOnlineCubit, bool>(
                builder: (context, isOnline) {
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return _OnlineToggle(
                        isOnline: isOnline,
                        pulseValue: isOnline ? _pulseAnimation.value : 1.0,
                        onToggle: _handleOnlineToggle,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: RiderDesignTokens.spacing40),

              // ── Quick Actions ───────────────────────────────────
              const _QuickActions(),

              const SizedBox(height: RiderDesignTokens.spacing24),

              // ── Status Message ─────────────────────────────────
              BlocBuilder<RiderOnlineCubit, bool>(
                builder: (context, isOnline) {
                  return _StatusIndicator(isOnline: isOnline);
                },
              ),

              const SizedBox(height: RiderDesignTokens.spacing16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String riderId;
  const _TopBar({required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RiderDesignTokens.spacing16,
        vertical: RiderDesignTokens.spacing12,
      ),
      child: Row(
        children: [
          // App logo / title
          const Text(
            'ZUBURB',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: RiderDesignTokens.brand,
            ),
          ),
          const SizedBox(width: RiderDesignTokens.spacing8),
          const Text(
            'RIDER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: RiderDesignTokens.textSecondary,
            ),
          ),
          const Spacer(),
          // SOS Button
          _IconActionButton(
            icon: Icons.sos,
            color: RiderDesignTokens.error,
            onTap: () {
              _showSosDialog(context);
            },
          ),
          const SizedBox(width: RiderDesignTokens.spacing8),
          // Menu
          _IconActionButton(
            icon: Icons.menu,
            color: RiderDesignTokens.textSecondary,
            onTap: () => _showDrawerMenu(context),
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
          'This will alert emergency contacts and support. Continue?',
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

  void _showDrawerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DrawerMenuSheet(riderId: riderId),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: RiderDesignTokens.surface,
          borderRadius: BorderRadius.circular(RiderDesignTokens.radius12),
          border: Border.all(color: RiderDesignTokens.border, width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ── Rider Profile Card ─────────────────────────────────────────────────────

class _RiderProfileCard extends StatelessWidget {
  const _RiderProfileCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduledRidesCubit, ScheduledRidesState>(
      builder: (context, state) {
        // Placeholder profile data — replace with actual rider profile
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: RiderDesignTokens.spacing16,
            vertical: RiderDesignTokens.spacing8,
          ),
          padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
          decoration: BoxDecoration(
            gradient: RiderDesignTokens.cardGradient,
            borderRadius: BorderRadius.circular(RiderDesignTokens.radius20),
            border: Border.all(color: RiderDesignTokens.border, width: 1),
            boxShadow: RiderDesignTokens.cardShadow,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [RiderDesignTokens.brand, RiderDesignTokens.brandDark],
                  ),
                  borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
                ),
                child: const Icon(
                  Icons.person,
                  color: RiderDesignTokens.textOnBrand,
                  size: 28,
                ),
              ),
              const SizedBox(width: RiderDesignTokens.spacing16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Rider',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: RiderDesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.9',
                          style: RiderDesignTokens.bodyMedium.copyWith(
                            color: RiderDesignTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: RiderDesignTokens.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '247 trips',
                          style: RiderDesignTokens.bodyMedium.copyWith(
                            color: RiderDesignTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Settings icon
              Icon(
                Icons.settings_outlined,
                color: RiderDesignTokens.textSecondary,
                size: 22,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Earnings Summary ────────────────────────────────────────────────────────

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary();

  @override
  Widget build(BuildContext context) {
    // Placeholder earnings data — connect to actual earnings bloc
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RiderDesignTokens.spacing16),
      child: Row(
        children: [
          Expanded(
            child: _EarningsCard(
              label: 'Today',
              amount: '\$47.50',
              icon: Icons.today,
              color: RiderDesignTokens.brand,
            ),
          ),
          const SizedBox(width: RiderDesignTokens.spacing12),
          Expanded(
            child: _EarningsCard(
              label: 'This Week',
              amount: '\$312.80',
              icon: Icons.date_range,
              color: RiderDesignTokens.stateAccepted,
            ),
          ),
          const SizedBox(width: RiderDesignTokens.spacing12),
          Expanded(
            child: _EarningsCard(
              label: 'Trips',
              amount: '12',
              icon: Icons.route,
              color: RiderDesignTokens.stateNavigate,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _EarningsCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RiderDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: RiderDesignTokens.surface,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
        border: Border.all(color: RiderDesignTokens.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: RiderDesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: RiderDesignTokens.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Online Toggle ────────────────────────────────────────────────────────────

class _OnlineToggle extends StatefulWidget {
  final bool isOnline;
  final double pulseValue;
  final Future<void> Function(bool) onToggle;

  const _OnlineToggle({
    required this.isOnline,
    required this.pulseValue,
    required this.onToggle,
  });

  @override
  State<_OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends State<_OnlineToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    );
    if (widget.isOnline) {
      _slideController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_OnlineToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    await widget.onToggle(!widget.isOnline);
    if (mounted) {
      setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.72;

    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              final glowOpacity = widget.isOnline ? widget.pulseValue * 0.4 : 0.0;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: widget.isOnline
                      ? [
                          BoxShadow(
                            color: RiderDesignTokens.brand.withOpacity(glowOpacity),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isOnline
                              ? RiderDesignTokens.brand
                              : RiderDesignTokens.border,
                          width: 3,
                        ),
                      ),
                    ),
                    // Inner ring
                    Container(
                      width: size * 0.85,
                      height: size * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isOnline
                            ? RiderDesignTokens.brand.withOpacity(0.12)
                            : RiderDesignTokens.surface,
                        border: Border.all(
                          color: widget.isOnline
                              ? RiderDesignTokens.brand.withOpacity(0.5)
                              : RiderDesignTokens.border,
                          width: 1,
                        ),
                      ),
                    ),
                    // Center content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status icon with rotation animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: widget.isOnline ? 1 : 0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * math.pi * 2,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isOnline
                                      ? RiderDesignTokens.brand
                                      : RiderDesignTokens.surfaceElevated,
                                ),
                                child: Icon(
                                  widget.isOnline ? Icons.check : Icons.power_settings_new,
                                  color: widget.isOnline
                                      ? RiderDesignTokens.textOnBrand
                                      : RiderDesignTokens.textSecondary,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: widget.isOnline
                                ? RiderDesignTokens.brand
                                : RiderDesignTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isOnline
                              ? 'Tap to go offline'
                              : 'Tap to go online',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: RiderDesignTokens.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isToggling)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: RiderDesignTokens.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RiderDesignTokens.spacing16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.history,
              label: 'Earnings',
              onTap: () => _showEarningsHistory(context),
            ),
          ),
          const SizedBox(width: RiderDesignTokens.spacing12),
          Expanded(
            child: _ActionButton(
              icon: Icons.event_note,
              label: 'Scheduled',
              badge: context.watch<ScheduledRidesCubit>().state is ScheduledRidesLoaded
                  ? ((context.read<ScheduledRidesCubit>().state as ScheduledRidesLoaded).count > 0 ? 1 : 0)
                  : 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduledRidesScreen(riderId: ''),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: RiderDesignTokens.spacing12),
          Expanded(
            child: _ActionButton(
              icon: Icons.support_agent,
              label: 'Support',
              onTap: () => _showSupportSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showEarningsHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(RiderDesignTokens.spacing24),
        decoration: const BoxDecoration(
          color: RiderDesignTokens.surfaceElevated,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RiderDesignTokens.radius24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RiderDesignTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Earnings History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RiderDesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _EarningsRow(label: 'Today', amount: '\$47.50'),
            _EarningsRow(label: 'Yesterday', amount: '\$62.00'),
            _EarningsRow(label: 'This Week', amount: '\$312.80'),
            _EarningsRow(label: 'Last Week', amount: '\$428.50'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(RiderDesignTokens.spacing24),
        decoration: const BoxDecoration(
          color: RiderDesignTokens.surfaceElevated,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RiderDesignTokens.radius24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RiderDesignTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: RiderDesignTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.help_outline, color: RiderDesignTokens.brand),
              title: const Text('FAQ', style: TextStyle(color: RiderDesignTokens.textPrimary)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: RiderDesignTokens.brand),
              title: const Text('Live Chat', style: TextStyle(color: RiderDesignTokens.textPrimary)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: RiderDesignTokens.brand),
              title: const Text('Call Support', style: TextStyle(color: RiderDesignTokens.textPrimary)),
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final String label;
  final String amount;
  const _EarningsRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: RiderDesignTokens.textSecondary)),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: RiderDesignTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: RiderDesignTokens.spacing16,
          horizontal: RiderDesignTokens.spacing12,
        ),
        decoration: BoxDecoration(
          color: RiderDesignTokens.surface,
          borderRadius: BorderRadius.circular(RiderDesignTokens.radius16),
          border: Border.all(color: RiderDesignTokens.border, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: RiderDesignTokens.textSecondary, size: 24),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: RiderDesignTokens.brand,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: RiderDesignTokens.textOnBrand,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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

// ── Status Indicator ───────────────────────────────────────────────────────

class _StatusIndicator extends StatelessWidget {
  final bool isOnline;
  const _StatusIndicator({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RiderDesignTokens.spacing20,
        vertical: RiderDesignTokens.spacing12,
      ),
      decoration: BoxDecoration(
        color: isOnline
            ? RiderDesignTokens.success.withOpacity(0.12)
            : RiderDesignTokens.surface,
        borderRadius: BorderRadius.circular(RiderDesignTokens.radius32),
        border: Border.all(
          color: isOnline
              ? RiderDesignTokens.success.withOpacity(0.3)
              : RiderDesignTokens.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? RiderDesignTokens.success : RiderDesignTokens.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isOnline
                ? 'Ready to receive rides'
                : 'You are offline',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isOnline ? RiderDesignTokens.success : RiderDesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Menu Sheet ────────────────────────────────────────────────────────

class _DrawerMenuSheet extends StatelessWidget {
  final String riderId;
  const _DrawerMenuSheet({required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RiderDesignTokens.surfaceElevated,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RiderDesignTokens.radius24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RiderDesignTokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _MenuItem(
              icon: Icons.person_outline,
              label: 'My Profile',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.history,
              label: 'Ride History',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.calendar_month,
              label: 'Availability & Schedule',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RiderAvailabilityScreen(riderId: riderId),
                  ),
                );
              },
            ),
            _MenuItem(
              icon: Icons.wallet,
              label: 'Wallet',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => Navigator.pop(context),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: RiderDesignTokens.border, height: 32),
            _MenuItem(
              icon: Icons.logout,
              label: 'Logout',
              color: RiderDesignTokens.error,
              onTap: () {
                Navigator.pop(context);
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? RiderDesignTokens.textPrimary;
    return ListTile(
      leading: Icon(icon, color: textColor.withOpacity(0.7), size: 22),
      title: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: textColor.withOpacity(0.3)),
      onTap: onTap,
    );
  }
}