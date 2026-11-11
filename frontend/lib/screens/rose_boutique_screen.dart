import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/boutique_provider.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';

class RoseBoutiqueScreen extends ConsumerStatefulWidget {
  const RoseBoutiqueScreen({super.key});

  @override
  ConsumerState<RoseBoutiqueScreen> createState() => _RoseBoutiqueScreenState();
}

class _RoseBoutiqueScreenState extends ConsumerState<RoseBoutiqueScreen> {
  Timer? _cooldownTimer;
  bool _adPlaying = false;
  int _adProgress = 0;
  Timer? _adProgressTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(boutiqueProvider.notifier).fetchBoutiqueData());

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        ref.read(boutiqueProvider.notifier).decrementCooldown();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _adProgressTimer?.cancel();
    super.dispose();
  }

  String _formatCooldown(int seconds) {
    final h = (seconds / 3600).floor().toString().padLeft(2, '0');
    final m = ((seconds % 3600) / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _triggerAdWatch() {
    setState(() {
      _adPlaying = true;
      _adProgress = 0;
    });

    _adProgressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _adProgress += 10;
      });

      if (_adProgress >= 100) {
        timer.cancel();
        setState(() {
          _adPlaying = false;
        });
        _claimAdReward();
      }
    });
  }

  Future<void> _claimAdReward() async {
    try {
      await ref.read(boutiqueProvider.notifier).watchAdReward();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Congratulations! Earned 1 Rose 🌹 from watching video.'),
          backgroundColor: PremiumTheme.darkEspresso,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PremiumTheme.crimsonRed),
      );
    }
  }

  Future<void> _claimFreeRose() async {
    try {
      await ref.read(boutiqueProvider.notifier).claimDailyRose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claimed 1 Daily Free Rose! 🌹'),
          backgroundColor: PremiumTheme.darkEspresso,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PremiumTheme.crimsonRed),
      );
    }
  }

  Future<void> _buyBundle(int amount, double price) async {
    try {
      await ref.read(boutiqueProvider.notifier).purchaseRoseBundle(amount, price);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Purchase Successful! 🌹',
            style: GoogleFonts.playfairDisplay(color: PremiumTheme.textWhite, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Successfully credited $amount Roses to your account balance.',
            style: GoogleFonts.inter(color: PremiumTheme.textSilver),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Perfect', style: GoogleFonts.inter(color: PremiumTheme.darkEspresso, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: PremiumTheme.crimsonRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boutiqueState = ref.watch(boutiqueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AestheticBackground(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. YOUR BALANCE CARD (Exact from Image 3)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A3728).withOpacity(0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'YOUR BALANCE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PremiumTheme.textMuted,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🌹', style: TextStyle(fontSize: 34)),
                              const SizedBox(width: 8),
                              Text(
                                '${boutiqueState.roseBalance}',
                                style: GoogleFonts.inter(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  color: PremiumTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Roses never expire · Use them wisely',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: PremiumTheme.textSilver,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2. Buy Roses Section Header
                    Row(
                      children: [
                        const Text('🌹', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Buy Roses',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: PremiumTheme.textWhite,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3-Card Row (Exact from Image 3)
                    Row(
                      children: [
                        Expanded(
                          child: _buildBuyCard(
                            emoji: '🌹',
                            title: 'A Single Rose',
                            price: '₹100',
                            onTap: () => _buyBundle(1, 100.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBuyCard(
                            emoji: '🌹🌹🌹',
                            badge: 'SAVE 30%',
                            title: 'The Bouquet',
                            price: '₹350',
                            onTap: () => _buyBundle(5, 350.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildBuyCard(
                            emoji: '🌹🌹🌹',
                            badge: 'MOST POPULAR',
                            title: 'Grand Gesture',
                            price: '₹1,150',
                            onTap: () => _buyBundle(20, 1150.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 3. Earn Free Roses Section
                    Text(
                      'Earn Free Roses',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.textWhite,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Daily Drop Card
                    _buildEarnCard(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Daily Drop',
                      subtitle: boutiqueState.claimCooldownSeconds > 0
                          ? 'Available in ${_formatCooldown(boutiqueState.claimCooldownSeconds)}'
                          : 'Claim 1 free rose every 48 hours',
                      buttonText: '+1 🌹',
                      onTap: boutiqueState.claimCooldownSeconds > 0 ? null : _claimFreeRose,
                    ),
                    const SizedBox(height: 12),

                    // Watch a Short Video Card
                    _buildEarnCard(
                      icon: Icons.smart_display_outlined,
                      title: 'Watch a Short Video',
                      subtitle: 'Help support the app',
                      buttonText: '+1 🌹',
                      onTap: _triggerAdWatch,
                    ),
                    const SizedBox(height: 12),

                    // Refer a Friend Card
                    _buildEarnCard(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'Refer a Friend',
                      subtitle: 'They get 1, you get 2!',
                      buttonText: boutiqueState.referralCode.isNotEmpty
                          ? boutiqueState.referralCode
                          : 'VARUDU-4BB1QQ',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Referral code copied: ${boutiqueState.referralCode}'),
                            backgroundColor: PremiumTheme.darkEspresso,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            if (_adPlaying) _buildAdPlayerOverlay(),
          ],
        ),
      ),
    );
  }

  /// 3-Card Row item from Image 3
  Widget _buildBuyCard({
    required String emoji,
    String? badge,
    required String title,
    required String price,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 165,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3728).withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top badge if any
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PremiumTheme.darkEspresso,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else
              const SizedBox(height: 18),

            // Emoji Roses
            Text(emoji, style: const TextStyle(fontSize: 22)),

            // Title & Price
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: PremiumTheme.textSilver,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: PremiumTheme.textWhite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Wide horizontal Earn Cards from Image 3
  Widget _buildEarnCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3728).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: PremiumTheme.darkEspresso),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PremiumTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: PremiumTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: onTap == null ? Colors.grey.shade400 : PremiumTheme.darkEspresso,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPlayerOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.95),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.slideshow_rounded, color: PremiumTheme.goldAccent, size: 72),
            const SizedBox(height: 24),
            Text(
              'Premium Advertisement Playing',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ad is playing to support matchmaking. Rewards will be issued shortly...',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 36),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _adProgress / 100.0,
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: PremiumTheme.goldAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(_adProgress / 10).round()}s / 10s',
              style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
