import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/boutique_provider.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';
import '../widgets/glassmorphic_container.dart';

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
    
    // Timer to tick down cooldown seconds
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
        _adProgress += 10; // Progress adds up to 100 in 10 seconds
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
          content: Text('Congratulations! Earned 1 Rose 🌹 from watching ad.'),
          backgroundColor: PremiumTheme.goldAccent,
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
          content: Text('Earned 1 Daily Free Rose! 🌹'),
          backgroundColor: PremiumTheme.goldAccent,
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
          title: Text('Purchase Successful! 🌹', style: GoogleFonts.cormorantGaramond(color: PremiumTheme.goldAccent, fontSize: 24, fontWeight: FontWeight.bold)),
          content: Text('Successfully credited $amount Roses to your account balance.', style: GoogleFonts.inter(color: PremiumTheme.textSilver)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Perfect', style: GoogleFonts.inter(color: PremiumTheme.goldAccent)),
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
        verticalText: 'BOUTIQUE',
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Banner Card
                    GlassmorphicContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.3), width: 1.5),
                      child: Column(
                        children: [
                          Text(
                            'YOUR BALANCE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PremiumTheme.goldAccent,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🌹', style: TextStyle(fontSize: 36)),
                              const SizedBox(width: 8),
                              Text(
                                '${boutiqueState.roseBalance}',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: PremiumTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Referral Code: ${boutiqueState.referralCode}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: PremiumTheme.textSilver,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Claim daily or ad reward buttons
                    Row(
                      children: [
                        // Daily Free rose
                        Expanded(
                          child: _buildActionCard(
                            title: 'Daily Claim',
                            iconText: '📅',
                            subtitle: boutiqueState.claimCooldownSeconds > 0
                                ? _formatCooldown(boutiqueState.claimCooldownSeconds)
                                : 'Ready to Claim',
                            isDisabled: boutiqueState.claimCooldownSeconds > 0,
                            onTap: _claimFreeRose,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Watch ad reward
                        Expanded(
                          child: _buildActionCard(
                            title: 'Watch Ad',
                            iconText: '🎬',
                            subtitle: 'Earn 1 Rose',
                            isDisabled: false,
                            onTap: _triggerAdWatch,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Purchase Bundles
                    Text(
                      'Purchase Rose Bundles',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildBundleCard(
                      roses: 1,
                      price: '₹100',
                      subtitle: 'Single gesture to grab immediate attention',
                      tag: 'STARTER',
                      onTap: () => _buyBundle(1, 100.0),
                    ),
                    _buildBundleCard(
                      roses: 5,
                      price: '₹350',
                      subtitle: 'Elegance package (Save 30%)',
                      tag: 'RECOMMENDED',
                      isGold: true,
                      onTap: () => _buyBundle(5, 350.0),
                    ),
                    _buildBundleCard(
                      roses: 20,
                      price: '₹1150',
                      subtitle: 'Grand gesture elite collection',
                      tag: 'BEST VALUE',
                      onTap: () => _buyBundle(20, 1150.0),
                    ),
                    const SizedBox(height: 32),

                    // History logs
                    Text(
                      'Transaction History',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: PremiumTheme.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (boutiqueState.transactions.isEmpty)
                      Center(
                        child: Text(
                          'No transactions recorded yet.',
                          style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 14),
                        ),
                      )
                    else
                      GlassmorphicContainer(
                        borderRadius: 16,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: boutiqueState.transactions.length,
                          separatorBuilder: (context, index) => const Divider(color: PremiumTheme.goldLight, height: 1),
                          itemBuilder: (context, index) {
                            final item = boutiqueState.transactions[index];
                            final amount = item['amount'] ?? 0;
                            final isCredit = amount > 0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCredit ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                child: Text(
                                  isCredit ? '+' : '-',
                                  style: TextStyle(color: isCredit ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              title: Text(item['description'] ?? 'Transaction', style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14)),
                              trailing: Text(
                                '${isCredit ? "" : ""}$amount Roses',
                                style: GoogleFonts.inter(
                                  color: isCredit ? Colors.green : PremiumTheme.crimsonRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                item['created_at'] != null 
                                    ? item['created_at'].toString().split('T')[0] 
                                    : '',
                                style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),

            // Custom ad simulation player overlay container
            if (_adPlaying)
              _buildAdPlayerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String iconText,
    required String subtitle,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: GlassmorphicContainer(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        borderRadius: 20,
        opacity: isDisabled ? 0.5 : 0.9,
        border: Border.all(color: PremiumTheme.goldBorder),
        child: Column(
          children: [
            Text(iconText, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDisabled ? PremiumTheme.textMuted : PremiumTheme.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDisabled ? PremiumTheme.crimsonRed : PremiumTheme.goldAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundleCard({
    required int roses,
    required String price,
    required String subtitle,
    required String tag,
    bool isGold = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        border: isGold ? Border.all(color: PremiumTheme.goldAccent, width: 1.5) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGold ? PremiumTheme.goldAccent.withOpacity(0.15) : PremiumTheme.goldBorder.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isGold ? PremiumTheme.goldAccent : PremiumTheme.textSilver,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('🌹', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text(
                        '$roses ${roses == 1 ? "Rose" : "Roses"}',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: PremiumTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: PremiumTheme.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isGold ? PremiumTheme.buttonGradient : null,
                color: isGold ? null : PremiumTheme.surfaceElevated,
                border: isGold ? null : Border.all(color: PremiumTheme.goldBorder),
                boxShadow: isGold
                    ? [BoxShadow(color: PremiumTheme.goldAccent.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Text(
                price,
                style: GoogleFonts.outfit(
                  color: isGold ? Colors.white : PremiumTheme.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
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
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
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

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _adProgress / 100.0,
                minHeight: 8,
                backgroundColor: Colors.white12,
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
