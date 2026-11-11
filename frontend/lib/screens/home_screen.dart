import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/premium_theme.dart';
import 'profiles_screen.dart';
import 'requests_screen.dart';
import 'rose_boutique_screen.dart';
import 'chat_screen.dart';
import 'settings_profile_screen.dart';
import '../widgets/aesthetic_background.dart';
import '../widgets/glassmorphic_container.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.profile != null) {
        ref.read(chatProvider.notifier).initSocket(authState.profile!['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Index 0: Dashboard Tab
      DashboardTab(onNavigate: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      // Index 1: Swipe Explore
      const ProfilesScreen(),
      // Index 2: Likes / Requests Tab
      const RequestsScreen(),
      // Index 3: Boutique Shop Tab
      const RoseBoutiqueScreen(),
      // Index 4: Chats Tab
      const ChatScreen(),
      // Index 5: Account Settings Tab
      const SettingsProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: PremiumTheme.primaryBgLight,
          border: const Border(
            top: BorderSide(
              color: PremiumTheme.goldBorder,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6E522E).withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: PremiumTheme.primaryBgLight,
          selectedItemColor: PremiumTheme.goldAccent,
          unselectedItemColor: PremiumTheme.textMuted,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Likes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Boutique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- DASHBOARD TAB SCREEN ----------------
class DashboardTab extends ConsumerWidget {
  final Function(int) onNavigate;

  const DashboardTab({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile ?? {};
    final roseBalance = profile['roses_balance'] ?? 0;

    return AestheticBackground(
      verticalText: 'VARUDU',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Balance and Logout Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassmorphicContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    borderRadius: 20,
                    border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.3)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌹', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '$roseBalance Roses',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: PremiumTheme.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    child: GlassmorphicContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      borderRadius: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout_rounded, size: 14, color: PremiumTheme.crimsonRed),
                          const SizedBox(width: 4),
                          Text(
                            'Logout',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PremiumTheme.textSilver,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Animated Pulsing Heart with Golden Halo
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PremiumTheme.surfaceCard,
                        border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTheme.goldAccent.withOpacity(0.25),
                            blurRadius: 28,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 42,
                        color: PremiumTheme.crimsonRed,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Brand Title
                    Text(
                      'Varudu Matrimony',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.textWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Vedic Ashtakoota compatibility analysis and royal rose connections.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: PremiumTheme.textSilver,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Search Filter Bar
              Row(
                children: [
                  Expanded(
                    child: GlassmorphicContainer(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      borderRadius: 16,
                      child: TextField(
                        style: GoogleFonts.inter(color: PremiumTheme.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Search city, caste, or name...',
                          hintStyle: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: PremiumTheme.goldAccent),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => onNavigate(1), // Go to Swipe
                    child: Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        gradient: PremiumTheme.buttonGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTheme.goldAccent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Launch Swiping Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: PremiumTheme.buttonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: PremiumTheme.goldAccent.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => onNavigate(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Discover Matching Profiles',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Grid Shortcuts (Likes, Rose Shop, Chats)
              Row(
                children: [
                  Expanded(
                    child: _buildShortCard(
                      'Likes Tab',
                      Icons.favorite_rounded,
                      PremiumTheme.crimsonRed,
                      () => onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortCard(
                      'Rose Shop',
                      Icons.auto_awesome,
                      PremiumTheme.goldAccent,
                      () => onNavigate(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortCard(
                      'Chats',
                      Icons.chat_bubble_rounded,
                      PremiumTheme.activeBlue,
                      () => onNavigate(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Ashtakoota Compatibility Prompt Box
              GlassmorphicContainer(
                padding: const EdgeInsets.all(18),
                borderRadius: 16,
                border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.25)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PremiumTheme.goldAccent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('✨', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horoscope Matchmaking',
                            style: GoogleFonts.cormorantGaramond(
                              fontWeight: FontWeight.bold,
                              color: PremiumTheme.goldAccent,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vedic Ashtakoota 36-point compatibility engine is active.',
                            style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortCard(String label, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        height: 100,
        borderRadius: 16,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: PremiumTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
