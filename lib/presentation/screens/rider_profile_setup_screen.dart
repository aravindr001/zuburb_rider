import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../repository/rider_repository.dart';
import '../widgets/primary_button.dart';
import '../widgets/animated_background.dart';

/// Screen shown to newly registered riders to collect their name and phone.
class RiderProfileSetupScreen extends StatefulWidget {
  final String riderId;
  final String? initialPhone;

  const RiderProfileSetupScreen({
    super.key,
    required this.riderId,
    this.initialPhone,
  });

  @override
  State<RiderProfileSetupScreen> createState() =>
      _RiderProfileSetupScreenState();
}

class _RiderProfileSetupScreenState extends State<RiderProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await context.read<RiderRepository>().createRiderProfile(
            riderId: widget.riderId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: const Color(0xFFFF4757),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00E5C3), Color(0xFF6C63FF)],
                  ).createShader(bounds),
                  child: const Text(
                    'GUARD',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .slideY(
                      begin: -0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 12),
                const Text(
                  'Rider',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                    color: Color(0xFF8A8A9A),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: -0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 48),
                const Text(
                  'Welcome! Complete your profile to get started.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    color: Color(0xFF8A8A9A),
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: -0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const Spacer(),
                // Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FULL NAME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF12121A),
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 20),
                // Phone (pre-filled, disabled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHONE NUMBER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      enabled: false,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8A8A9A),
                        letterSpacing: 0.1,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.02),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 250),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Continue',
                    loading: _isSaving,
                    onPressed: _isSaving ? null : _submit,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 300),
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
