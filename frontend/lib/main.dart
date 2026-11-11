
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'services/api_service.dart';
import 'widgets/active_call_overlay.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/intro_video_screen.dart';
import 'theme/premium_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadBaseUrl();
  runApp(
    const ProviderScope(
      child: MatrimonyApp(),
    ),
  );
}

class MatrimonyApp extends StatelessWidget {
  const MatrimonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Varudu Matrimony',
      debugShowCheckedModeBanner: false,
      theme: PremiumTheme.lightTheme,
      home: const IntroVideoScreen(),
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final chatState = ref.watch(chatProvider);
            final authState = ref.watch(authProvider);
            final currentUserId = authState.profile?['id'];
            
            return Stack(
              children: [
                if (child != null) child,
                if (chatState.isInCall && chatState.callPartnerId != null && currentUserId != null)
                  Positioned.fill(
                    child: ActiveCallOverlay(
                      partner: chatState.matches.firstWhere(
                        (m) => m['partnerId'] == chatState.callPartnerId,
                        orElse: () => null,
                      )?['profile'] ?? {
                        'id': chatState.callPartnerId,
                        'name': chatState.callPartnerName ?? 'User',
                        'photos': chatState.callPartnerPhoto != null ? [chatState.callPartnerPhoto] : [],
                      },
                      isIncoming: chatState.isIncomingCall,
                      status: chatState.callStatus ?? 'dialing',
                      onAccept: () {
                        ref.read(chatProvider.notifier).acceptCall(chatState.callPartnerId!, currentUserId);
                      },
                      onDecline: () {
                        ref.read(chatProvider.notifier).rejectCall(chatState.callPartnerId!, currentUserId);
                      },
                      onEnd: () {
                        ref.read(chatProvider.notifier).endCall(currentUserId, chatState.callPartnerId!);
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.initial:
        return const SplashLoadingScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.otpSent:
        return const OtpScreen();
      case AuthStatus.onboardingRequired:
        return const OnboardingScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.loading:
        if (authState.profile != null) {
          return const HomeScreen();
        } else {
          return const SplashLoadingScreen();
        }
      case AuthStatus.error:
        return const LoginScreen();
    }
  }
}

class SplashLoadingScreen extends StatelessWidget {
  const SplashLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFFFAF7F2), Color(0xFFF0E8DC)],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: PremiumTheme.goldAccent, width: 2),
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 64,
                  color: PremiumTheme.crimsonRed,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Varudu Matrimony',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.textWhite,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecting Hearts, Uniting Souls',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: PremiumTheme.textSilver,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: PremiumTheme.goldAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
