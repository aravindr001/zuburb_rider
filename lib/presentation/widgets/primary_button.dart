import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.danger = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.loading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          color: widget.danger
              ? const Color(0xFFFF4757)
              : const Color(0xFF00E5C3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled && _pressed
              ? [
                  BoxShadow(
                    color: widget.danger
                        ? const Color(0xFFFF4757).withOpacity(0.4)
                        : const Color(0xFF00E5C3).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0F)),
                  ),
                )
              : Text(
                  widget.text,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    )
        .animate(target: _pressed ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.97, 0.97),
          duration: const Duration(milliseconds: 150),
        );
  }
}
