import 'package:flutter/material.dart';

/// Zuburb Rider Design Token System
/// Dark-first premium aesthetic for the rider app
class RiderDesignTokens {
  RiderDesignTokens._();

  // ── Brand Colors ──────────────────────────────────────────────

  /// Primary brand — electric lime / neon green
  static const Color brand = Color(0xFFA8FF3E);

  /// Brand on dark
  static const Color brandDark = Color(0xFF7AC328);

  /// Secondary brand — used for accents
  static const Color brandSecondary = Color(0xFF3EFF8C);

  // ── Background & Surface ──────────────────────────────────────

  /// True dark background
  static const Color background = Color(0xFF0A0A0F);

  /// Elevated surface (cards, sheets)
  static const Color surface = Color(0xFF141420);

  /// Higher elevation (dialogs, modals)
  static const Color surfaceElevated = Color(0xFF1E1E2E);

  /// Subtle surface variant
  static const Color surfaceSubtle = Color(0xFF1A1A28);

  // ── State Accent Colors (5-State Machine) ─────────────────────

  /// ACCEPTED state — Electric Blue
  static const Color stateAccepted = Color(0xFF00B4FF);

  /// NAVIGATE state — Amber/Orange
  static const Color stateNavigate = Color(0xFFFF9800);

  /// OTP_VERIFY state — Purple
  static const Color stateOtp = Color(0xFF9C27B0);

  /// PICKUP state — Teal/Green
  static const Color statePickup = Color(0xFF00BFA5);

  /// COMPLETE state — Lime/Green
  static const Color stateComplete = Color(0xFFA8FF3E);

  // ── Semantic Colors ───────────────────────────────────────────

  /// Success / online
  static const Color success = Color(0xFF4CAF50);

  /// Error / cancel / danger
  static const Color error = Color(0xFFFF5252);

  /// Warning / caution
  static const Color warning = Color(0xFFFFB300);

  /// Info / neutral
  static const Color info = Color(0xFF2196F3);

  /// Surge pricing indicator
  static const Color surge = Color(0xFFFF6B00);

  // ── Text Colors ────────────────────────────────────────────────

  /// Primary text on dark
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary / muted text
  static const Color textSecondary = Color(0xFFB0B0C0);

  /// Tertiary / hint text
  static const Color textTertiary = Color(0xFF6B6B80);

  /// Text on brand color
  static const Color textOnBrand = Color(0xFF0A0A0F);

  // ── Border & Divider ───────────────────────────────────────────

  /// Subtle border
  static const Color border = Color(0xFF2A2A3A);

  /// Stronger border
  static const Color borderStrong = Color(0xFF3A3A50);

  // ── Gradients ─────────────────────────────────────────────────

  /// Background gradient (top to bottom)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0F1A), Color(0xFF0A0A0F)],
  );

  /// Card gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF141420)],
  );

  /// Brand glow gradient
  static const LinearGradient brandGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFA8FF3E), Color(0xFF7AC328)],
  );

  /// Online toggle glow
  static const LinearGradient onlineGlowGradient = LinearGradient(
    colors: [Color(0xFFA8FF3E), Color(0xFF00FF88), Color(0xFF00D4FF)],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Spacing ────────────────────────────────────────────────────

  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;

  // ── Border Radius ─────────────────────────────────────────────

  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius10 = 10.0;
  static const double radius12 = 12.0;
  static const double radius14 = 14.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius28 = 28.0;
  static const double radius32 = 32.0;
  static const double radius40 = 40.0;
  static const double radiusCircle = 9999.0;

  // ── Elevation / Shadow ────────────────────────────────────────

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> brandGlowShadow = [
    BoxShadow(
      color: Color(0x60A8FF3E),
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];

  // ── Typography ────────────────────────────────────────────────

  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: textPrimary,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: textPrimary,
    height: 1.15,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: textPrimary,
    height: 1.25,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: textSecondary,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.3,
  );

  // ── Animation Durations ───────────────────────────────────────

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // ── Icon Sizes ────────────────────────────────────────────────

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconHuge = 64.0;

  // ── Button Heights ────────────────────────────────────────────

  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 52.0;
  static const double buttonHeightLarge = 60.0;
  static const double buttonHeightXLarge = 72.0;

  // ── State Machine Helpers ─────────────────────────────────────

  /// Returns the accent color for a given ride state
  static Color colorForState(RideState state) {
    switch (state) {
      case RideState.accepted:
        return stateAccepted;
      case RideState.navigate:
        return stateNavigate;
      case RideState.otpVerify:
        return stateOtp;
      case RideState.pickup:
        return statePickup;
      case RideState.complete:
        return stateComplete;
    }
  }

  /// Returns the icon for a given ride state
  static IconData iconForState(RideState state) {
    switch (state) {
      case RideState.accepted:
        return Icons.check_circle_outline;
      case RideState.navigate:
        return Icons.navigation;
      case RideState.otpVerify:
        return Icons.pin_invoke;
      case RideState.pickup:
        return Icons.person_add_alt;
      case RideState.complete:
        return Icons.flag;
    }
  }

  /// Returns the label for a given ride state
  static String labelForState(RideState state) {
    switch (state) {
      case RideState.accepted:
        return 'ACCEPTED';
      case RideState.navigate:
        return 'NAVIGATE';
      case RideState.otpVerify:
        return 'VERIFY OTP';
      case RideState.pickup:
        return 'PICKUP';
      case RideState.complete:
        return 'COMPLETE';
    }
  }
}

/// The 5 states in the rider ride machine
enum RideState {
  accepted,
  navigate,
  otpVerify,
  pickup,
  complete,
}