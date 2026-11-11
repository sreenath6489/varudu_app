import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _showServerUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Configure API Server URL',
            style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the backend URL (e.g. from Render or local tunnel)',
                style: GoogleFonts.hankenGrotesk(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Server Base URL',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'https://shubamasthu-backend.onrender.com',
                  hintStyle: const TextStyle(color: Colors.white30),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.goldAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  await ApiService.saveBaseUrl(url);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Server URL updated to: $url'),
                        backgroundColor: PremiumTheme.goldAccent,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
      verticalText: 'LOGIN',
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
                  Row(
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
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings, color: PremiumTheme.textWhite, size: 20),
                        onPressed: () => _showServerUrlDialog(context),
                        tooltip: 'Configure API Server URL',
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // Simulated dismiss behavior
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unified Auth - Dismissed'),
                          duration: Duration(milliseconds: 700),
                        ),
                      );
                    },
                    icon: const Icon(Icons.close, color: PremiumTheme.textWhite, size: 22),
                  ),
                ],
              ),
            ),

            // 2. Main Login Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Glassmorphic Asymmetric card shifted right
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
                                            'IDENTIFICATION',
                                            style: GoogleFonts.hankenGrotesk(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.5,
                                              color: PremiumTheme.textWhite.withOpacity(0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Welcome back.',
                                            style: GoogleFonts.cormorantGaramond(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: PremiumTheme.textWhite,
                                              height: 1.1,
                                            ),
                                          ),
                                          const SizedBox(height: 36),

                                          // Email Input Field
                                          AnimatedSlideField(
                                            focusNode: _emailFocusNode,
                                            child: TextFormField(
                                              controller: _emailController,
                                              focusNode: _emailFocusNode,
                                              keyboardType: TextInputType.emailAddress,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 16,
                                                color: PremiumTheme.textWhite,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Email or Mobile Number',
                                                hintStyle: GoogleFonts.hankenGrotesk(
                                                  color: PremiumTheme.textWhite.withOpacity(0.3),
                                                  fontSize: 15,
                                                ),
                                                suffixIcon: Icon(
                                                  Icons.alternate_email_rounded,
                                                  color: PremiumTheme.textWhite.withOpacity(0.25),
                                                  size: 20,
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
                                                  return 'Please enter your email or mobile';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          // Subtitle/Caption link (editorial bypass style)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: _bypassLogin,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Text(
                                                  'BYPASS VERIFICATION? — RUN MOCK ACCESS',
                                                  style: GoogleFonts.hankenGrotesk(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    fontStyle: FontStyle.italic,
                                                    color: PremiumTheme.textWhite.withOpacity(0.6),
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Styled separator
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: PremiumTheme.textWhite.withOpacity(0.08),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                child: Text(
                                                  'OR',
                                                  style: GoogleFonts.hankenGrotesk(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: PremiumTheme.textWhite.withOpacity(0.3),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: PremiumTheme.textWhite.withOpacity(0.08),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          // Social Google sign-in layout
                                          Center(
                                            child: InkWell(
                                              onTap: () {
                                                _emailController.text = 'google.user@example.com';
                                                _bypassLogin();
                                              },
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: PremiumTheme.textWhite.withOpacity(0.1),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.g_mobiledata_rounded,
                                                      color: PremiumTheme.textWhite,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Sign in with Google',
                                                      style: GoogleFonts.hankenGrotesk(
                                                        color: PremiumTheme.textWhite,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 12.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                        'New member?',
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'All accounts are created automatically via Verification Code OTP login!',
                          ),
                          backgroundColor: PremiumTheme.goldAccent,
                        ),
                      );
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
                      'CREATE ACCOUNT',
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

            // 4. Bottom Gradient line
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
