import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
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

    // Listen to error notifications
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: PremiumTheme.goldAccent,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final isLoading = authState.status == AuthStatus.loading;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return AestheticBackground(
      verticalText: 'VERIFY',
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Navigation Brand Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VARUDU',
                    style: GoogleFonts.syne(
                      fontSize: isTablet ? 24 : 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: PremiumTheme.textWhite,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.arrow_back, color: PremiumTheme.textWhite, size: 22),
                  ),
                ],
              ),
            ),

            // 2. Main OTP Form Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Glassmorphic card shifted right
                        Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: 0.88,
                            child: Container(
                              decoration: BoxDecoration(
                                color: PremiumTheme.surfaceCard.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: PremiumTheme.goldBorder,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: PremiumTheme.textWhite.withOpacity(0.04),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 36.0,
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            'SECURITY',
                                            style: GoogleFonts.hankenGrotesk(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.5,
                                              color: PremiumTheme.textWhite.withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Verify Code.',
                                            style: GoogleFonts.cormorantGaramond(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: PremiumTheme.textWhite,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'We sent a 4-digit code to\n${authState.email ?? "your device"}',
                                            style: GoogleFonts.hankenGrotesk(
                                              fontSize: 13,
                                              color: PremiumTheme.textWhite.withOpacity(0.6),
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Mock verification banner
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: PremiumTheme.textWhite.withOpacity(0.03),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: PremiumTheme.textWhite.withOpacity(0.05),
                                              ),
                                            ),
                                            child: Text(
                                              'For testing, enter code: 1234',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: PremiumTheme.textWhite.withOpacity(0.7),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // OTP Entry Field
                                          AnimatedSlideField(
                                            focusNode: _otpFocusNode,
                                            child: TextFormField(
                                              controller: _otpController,
                                              focusNode: _otpFocusNode,
                                              keyboardType: TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 8,
                                                color: PremiumTheme.textWhite,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: '0000',
                                                hintStyle: GoogleFonts.hankenGrotesk(
                                                  color: PremiumTheme.textWhite.withOpacity(0.2),
                                                  letterSpacing: 8,
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                                enabledBorder: UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: PremiumTheme.textWhite.withOpacity(0.12),
                                                  ),
                                                ),
                                                focusedBorder: const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: PremiumTheme.textWhite,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                errorBorder: const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: PremiumTheme.textWhite,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                focusedErrorBorder: const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: PremiumTheme.textWhite,
                                                    width: 2.0,
                                                  ),
                                                ),
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
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Overlapping Pulsing FAB at bottom right
                        Positioned(
                          right: 12,
                          bottom: -32,
                          child: PulsingFab(
                            onPressed: _submit,
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Utility Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLLECTION 2026',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textWhite.withOpacity(0.4),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Wrong details?',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PremiumTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.goldAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'CHANGE ACCOUNT',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom Decorative Line
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PremiumTheme.goldBorder,
                    PremiumTheme.goldAccent,
                    PremiumTheme.goldBorder,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Micro-interaction: Slides input text field to the right on focus
class AnimatedSlideField extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const AnimatedSlideField({
    super.key,
    required this.focusNode,
    required this.child,
  });

  @override
  State<AnimatedSlideField> createState() => _AnimatedSlideFieldState();
}

class _AnimatedSlideFieldState extends State<AnimatedSlideField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      transform: Matrix4.translationValues(_isFocused ? 8.0 : 0.0, 0.0, 0.0),
      child: widget.child,
    );
  }
}

// Pulse animation for the Floating Action Button (FAB)
class PulsingFab extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const PulsingFab({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<PulsingFab> createState() => _PulsingFabState();
}

class _PulsingFabState extends State<PulsingFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(
          parent: _pulseController,
          curve: Curves.easeInOut,
        ),
      ),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: PremiumTheme.textWhite,
          boxShadow: [
            BoxShadow(
              color: PremiumTheme.textWhite.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
