import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/premium_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).verifyOtp(_otpController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: PremiumTheme.crimsonRed,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [PremiumTheme.primaryBgDark, PremiumTheme.primaryBgBlack],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shield Lock Icon in Gold
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: PremiumTheme.surfaceCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.goldAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTheme.goldAccent.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_person_outlined,
                        size: 52,
                        color: PremiumTheme.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Header
                    Text(
                      'Verification Code',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'We sent a 4-digit code to\n${authState.email ?? ""}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: PremiumTheme.textSilver,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mock hint
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: PremiumTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'For testing, enter code: 1234',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: PremiumTheme.goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // OTP Entry Field
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: PremiumTheme.textWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: '0000',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade700,
                          letterSpacing: 8,
                        ),
                        filled: true,
                        fillColor: PremiumTheme.surfaceCard,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PremiumTheme.goldAccent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter OTP';
                        }
                        if (value.trim().length != 4) {
                          return 'OTP must be 4 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          gradient: PremiumTheme.goldGradient,
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: PremiumTheme.primaryBgBlack,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Verify & Continue',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: PremiumTheme.primaryBgBlack,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back Button
                    TextButton(
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                      },
                      child: Text(
                        'Change Account Detail',
                        style: GoogleFonts.inter(
                          color: PremiumTheme.crimsonRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
