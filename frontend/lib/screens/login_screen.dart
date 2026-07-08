import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/premium_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).sendOtp(_emailController.text.trim());
    }
  }

  void _bypassLogin() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter any email or phone number for bypass mode.'),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
      return;
    }
    ref.read(authProvider.notifier).bypassAuth(_emailController.text.trim());
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
                    // pulsing heart logo in Gold
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
                        Icons.favorite_rounded,
                        size: 52,
                        color: PremiumTheme.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Brand name in Cormorant Garamond Serif
                    Text(
                      'Varudu Matrimony',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.textWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P E R F M A T C H',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PremiumTheme.goldAccent,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Elite Matrimony for Connecting Hearts',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: PremiumTheme.textSilver,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email/Phone Number Text Field
                    TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Email or Mobile Number',
                        hintStyle: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 15),
                        prefixIcon: const Icon(Icons.account_circle_outlined, color: PremiumTheme.goldAccent),
                        filled: true,
                        fillColor: PremiumTheme.surfaceCard,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PremiumTheme.goldAccent, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PremiumTheme.crimsonRed, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: PremiumTheme.crimsonRed, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email or mobile';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button (Gold Capsule)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          gradient: PremiumTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: PremiumTheme.goldAccent.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
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
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Send Verification Code',
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

                    // Bypass Option for Testing
                    TextButton.icon(
                      onPressed: isLoading ? null : _bypassLogin,
                      icon: const Icon(Icons.rocket_launch_rounded, color: PremiumTheme.activeBlue, size: 18),
                      label: Text(
                        'Development Bypass (Mock login)',
                        style: GoogleFonts.inter(
                          color: PremiumTheme.activeBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Google OAuth placeholder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 1,
                          color: Colors.grey.shade800,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'Or sign in with',
                            style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 1,
                          color: Colors.grey.shade800,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Sign In Mock Button
                    GestureDetector(
                      onTap: () {
                        _emailController.text = 'google.user@example.com';
                        _bypassLogin();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: PremiumTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Sign in with Google',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
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
