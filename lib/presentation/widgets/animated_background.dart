import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0F),
          ),
        ),
        // Animated gradient orbs
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5C3).withOpacity(0.15),
                  const Color(0xFF00E5C3).withOpacity(0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: const Duration(milliseconds: 4000),
                curve: Curves.easeInOut,
              )
              .fade(
                begin: 0.3,
                end: 0.6,
                duration: const Duration(milliseconds: 4000),
              ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.12),
                  const Color(0xFF6C63FF).withOpacity(0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: const Duration(milliseconds: 5000),
                curve: Curves.easeInOut,
              )
              .fade(
                begin: 0.2,
                end: 0.5,
                duration: const Duration(milliseconds: 5000),
              ),
        ),
        // Content
        child,
      ],
    );
  }
}
