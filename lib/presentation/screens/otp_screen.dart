import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/animated_background.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;

  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pop(context);
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF4757),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 300))
                      .slideX(
                        begin: -0.2,
                        end: 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                  const Spacer(),
                  // Title
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
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
                  const SizedBox(height: 8),
                  const Text(
                    'We sent a verification code to your phone',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                      color: Color(0xFF8A8A9A),
                    ),
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
                  const SizedBox(height: 48),
                  // OTP input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERIFICATION CODE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: Color(0xFF8A8A9A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: '● ● ● ● ● ●',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            letterSpacing: 12,
                          ),
                          counterText: '',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
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
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: 'Verify',
                      loading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () {
                              final otp = otpController.text.trim();
                              if (otp.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter OTP'),
                                    backgroundColor: Color(0xFFFF4757),
                                  ),
                                );
                                return;
                              }

                              context.read<AuthBloc>().add(
                                    VerifyOtpEvent(
                                      widget.verificationId,
                                      otp,
                                    ),
                                  );
                            },
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
          );
        },
        ),
      ),
    );
  }
}
