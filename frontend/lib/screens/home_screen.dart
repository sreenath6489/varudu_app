import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/premium_theme.dart';
import 'profiles_screen.dart';
import 'requests_screen.dart';
import 'rose_boutique_screen.dart';
import 'chat_screen.dart';
import 'settings_profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

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
      backgroundColor: PremiumTheme.primaryBgBlack,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white10,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: PremiumTheme.primaryBgBlack,
          selectedItemColor: PremiumTheme.goldAccent,
          unselectedItemColor: PremiumTheme.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: false,
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Logout Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🌹', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
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
                GestureDetector(
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: PremiumTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
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
            const SizedBox(height: 30),

            // Pulsing Heart Center
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: PremiumTheme.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: PremiumTheme.goldAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: PremiumTheme.goldAccent.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 40,
                      color: PremiumTheme.crimsonRed,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Title
                  Text(
                    'Varudu Matrimony',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: PremiumTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Vedic Ashtakoota compatibility analysis and premium rose connections.',
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
            const SizedBox(height: 36),

            // Search Filter button
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: PremiumTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search matching location or caste...',
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
                      color: PremiumTheme.goldAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.tune_rounded,
                      color: PremiumTheme.primaryBgBlack,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick launch swiping button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: PremiumTheme.buttonGradient,
                ),
                child: ElevatedButton(
                  onPressed: () => onNavigate(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Discover Matching Profiles',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Grid cards routing shortcuts
            Row(
              children: [
                Expanded(
                  child: _buildShortCard(
                    'Likes Tab',
                    Icons.favorite_border_rounded,
                    () => onNavigate(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShortCard(
                    'Rose Shop',
                    Icons.auto_awesome_outlined,
                    () => onNavigate(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildShortCard(
                    'Chats Window',
                    Icons.chat_bubble_outline_rounded,
                    () => onNavigate(4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ashtakoota compatibility prompt box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PremiumTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Horoscope Matchmaking',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: PremiumTheme.goldLight, fontSize: 13),
                        ),
                        Text(
                          'Vedic Ashtakoota score checks out of 36 points are active.',
                          style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 11.5),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildShortCard(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: PremiumTheme.goldAccent),
            const SizedBox(height: 10),
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
