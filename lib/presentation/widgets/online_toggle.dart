import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnlineToggle extends StatefulWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onChanged,
  });

  @override
  State<OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends State<OnlineToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onChanged(!widget.isOnline);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: 200,
        height: 72,
        decoration: BoxDecoration(
          gradient: widget.isOnline
              ? const LinearGradient(
                  colors: [Color(0xFF00E5C3), Color(0xFF00C9AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isOnline ? null : const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: widget.isOnline
                ? const Color(0xFF00E5C3).withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: 2,
          ),
          boxShadow: widget.isOnline
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5C3).withOpacity(0.5),
                    blurRadius: 32,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5C3).withOpacity(0.3),
                    blurRadius: 64,
                    spreadRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Animated background glow
            if (widget.isOnline)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5C3).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .fade(
                      begin: 0.3,
                      end: 0.7,
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                    ),
              ),
            // Indicator circle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: widget.isOnline ? 140 : 6,
              top: 6,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      widget.isOnline ? const Color(0xFF0A0A0F) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.isOnline
                          ? const Color(0xFF00E5C3).withOpacity(0.5)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: widget.isOnline
                          ? const Color(0xFF00E5C3)
                          : const Color(0xFF8A8A9A),
                      shape: BoxShape.circle,
                      boxShadow: widget.isOnline
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00E5C3).withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  )
                      .animate(
                        target: widget.isOnline ? 1 : 0,
                        onPlay: (controller) => widget.isOnline
                            ? controller.repeat(reverse: true)
                            : null,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.4, 1.4),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .fade(
                        begin: 1.0,
                        end: 0.6,
                        duration: const Duration(milliseconds: 1000),
                      ),
                ),
              ),
            ),
            // Text
            Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color:
                      widget.isOnline ? const Color(0xFF0A0A0F) : Colors.white,
                ),
                child: Text(widget.isOnline ? 'ONLINE' : 'OFFLINE'),
              ),
            ),
          ],
        ),
      )
          .animate(target: _pressed ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(0.95, 0.95),
            duration: const Duration(milliseconds: 150),
          ),
    );
  }
}
