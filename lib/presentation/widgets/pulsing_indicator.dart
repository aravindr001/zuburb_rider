import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PulsingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const PulsingIndicator({
    super.key,
    this.size = 80,
    this.color = const Color(0xFF00E5C3),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outermost pulsing ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 3,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.5, 1.5),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
              )
              .fade(
                begin: 0.8,
                end: 0.0,
                duration: const Duration(milliseconds: 1200),
              ),
          // Second ring
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 3,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
              )
              .fade(
                begin: 0.8,
                end: 0.0,
                duration: const Duration(milliseconds: 1000),
              ),
          // Third ring
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 2,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
              )
              .fade(
                begin: 0.8,
                end: 0.0,
                duration: const Duration(milliseconds: 800),
              ),
          // Center glow
          Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.6),
                  color.withOpacity(0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
              )
              .fade(
                begin: 0.4,
                end: 0.8,
                duration: const Duration(milliseconds: 1000),
              ),
          // Center dot
          Container(
            width: size * 0.25,
            height: size * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.8),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }
}
