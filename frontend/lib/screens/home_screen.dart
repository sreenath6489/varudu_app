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

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Index 0: Home Hero Tab (Exact varudu.in match)
      VaruduHomeHeroTab(onNavigate: _onTabSelected),
      // Index 1: Discover / Swipe Cards (varudu.in/discover)
      const ProfilesScreen(),
      // Index 2: Likes / Requests (varudu.in/interests)
      const RequestsScreen(),
      // Index 3: Rose Boutique Shop (varudu.in/store)
      const RoseBoutiqueScreen(),
      // Index 4: Chats & Matches (varudu.in/chat)
      const ChatScreen(),
      // Index 5: Account & Verification (varudu.in/profile)
      const SettingsProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgLight,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),

          // Floating Top Navigation Bar (matching varudu.in top icon dock)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildTopNavigationDock(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The 6-icon top dock seen across all varudu.in screenshots
  Widget _buildTopNavigationDock() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3728).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDockIcon(0, Icons.home_rounded),
            _buildDockIcon(1, Icons.explore_rounded),
            _buildDockIcon(2, Icons.favorite_rounded),
            _buildDockIcon(3, Icons.auto_awesome_rounded),
            _buildDockIcon(4, Icons.chat_bubble_rounded),
            _buildDockIcon(5, Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDockIcon(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5DDD1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? PremiumTheme.darkEspresso : PremiumTheme.textSilver,
        ),
      ),
    );
  }
}

// ---------------- HERO TAB (EXACT REPLICA OF varudu.in HOME SCREEN) ----------------
class VaruduHomeHeroTab extends StatefulWidget {
  final Function(int) onNavigate;

  const VaruduHomeHeroTab({super.key, required this.onNavigate});

  @override
  State<VaruduHomeHeroTab> createState() => _VaruduHomeHeroTabState();
}

class _VaruduHomeHeroTabState extends State<VaruduHomeHeroTab> {
  String _lookingFor = 'Bride';
  String _ageRange = '22 - 30';
  String _religion = 'Any';
  String _location = 'Any';

  @override
  Widget build(BuildContext context) {
    return AestheticBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // 1. Center Hero Logo: "Varudu" with metallic gold gradient & swash flourish
            ShaderMask(
              shaderCallback: (bounds) => PremiumTheme.logoGoldGradient.createShader(bounds),
              child: Text(
                'Varudu',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 68,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. Subtitle: "Meaningful Matches for a Brighter Tomorrow"
            Text(
              'Meaningful Matches\nfor a Brighter Tomorrow',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                letterSpacing: 2.0,
                color: const Color(0xFF7A6A5C),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // 3. Lotus ornament line divider
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 32, height: 1, color: PremiumTheme.goldBorder),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text('🪷', style: TextStyle(fontSize: 13)),
                ),
                Container(width: 32, height: 1, color: PremiumTheme.goldBorder),
              ],
            ),
            const SizedBox(height: 36),

            // 4. Signature Capsule Search Bar (from Image 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A3728).withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Filter Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSearchFilterItem('Looking for', _lookingFor, ['Bride', 'Groom'], (val) {
                          setState(() => _lookingFor = val);
                        }),
                        _buildDivider(),
                        _buildSearchFilterItem('Age range', _ageRange, ['20 - 25', '22 - 30', '28 - 35'], (val) {
                          setState(() => _ageRange = val);
                        }),
                      ],
                    ),
                    const Divider(color: Color(0xFFF0EAE1), height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSearchFilterItem('Religion', _religion, ['Any', 'Hindu', 'Christian', 'Muslim'], (val) {
                          setState(() => _religion = val);
                        }),
                        _buildDivider(),
                        _buildSearchFilterItem('Location', _location, ['Any', 'Hyderabad', 'Bangalore', 'Tirupati'], (val) {
                          setState(() => _location = val);
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Deep Espresso Coffee "Search" Pill Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(1), // Open Discover tab
                        icon: const Icon(Icons.search, size: 18, color: Colors.white),
                        label: Text(
                          'Search',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumTheme.darkEspresso,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Logout Button (as seen in Image 1)
            Consumer(
              builder: (context, ref, _) {
                return GestureDetector(
                  onTap: () => ref.read(authProvider.notifier).logout(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PremiumTheme.goldBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout_rounded, size: 14, color: PremiumTheme.textSilver),
                        const SizedBox(width: 6),
                        Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: PremiumTheme.textSilver,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: const Color(0xFFF0EAE1),
    );
  }

  Widget _buildSearchFilterItem(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((opt) {
        return PopupMenuItem<String>(
          value: opt,
          child: Text(opt, style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textWhite)),
        );
      }).toList(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: PremiumTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentValue,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PremiumTheme.textWhite,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: PremiumTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
