import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';

class AstroMatchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> targetUser;

  const AstroMatchScreen({super.key, required this.targetUser});

  @override
  ConsumerState<AstroMatchScreen> createState() => _AstroMatchScreenState();
}

class _AstroMatchScreenState extends ConsumerState<AstroMatchScreen> {
  Map<String, dynamic>? _matchDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAstroDetails();
  }

  Future<void> _fetchAstroDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final details = await apiService.getAstroMatch(widget.targetUser['id']);
      setState(() {
        _matchDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _unlockAstro() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final res = await apiService.unlockAstroMatch(widget.targetUser['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Successfully unlocked compatibility report!'),
          backgroundColor: PremiumTheme.goldAccent,
        ),
      );

      // Refresh data
      _fetchAstroDetails();

      // Deduct locally from auth provider
      final authState = ref.read(authProvider);
      if (authState.profile != null && res['roses_balance'] != null) {
        final updated = Map<String, dynamic>.from(authState.profile!)
          ..['roses_balance'] = res['roses_balance'];
        ref.read(authProvider.notifier).updateProfile(updated);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      appBar: AppBar(
        title: Text(
          'ASTROLOGY MATCH',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PremiumTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: GoogleFonts.inter(color: PremiumTheme.crimsonRed),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_matchDetails == null) return const SizedBox();
    
    final curAstro = _matchDetails!['currentUserAstrology'] ?? {};
    final tarAstro = _matchDetails!['targetUserAstrology'] ?? {};
    final isUnlocked = _matchDetails!['unlocked'] == true;
    final score = _matchDetails!['score'] ?? 0;
    final breakdown = _matchDetails!['pointsBreakdown'] as Map<String, dynamic>? ?? {};

    return Stack(
      children: [
        // Main scroll content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Horoscope circular comparison card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAstroNode('You', curAstro['rasi'] ?? 'Aries', curAstro['star'] ?? 'Ashwini'),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white12,
                        ),
                        _buildAstroNode(widget.targetUser['name'] ?? 'Target', tarAstro['rasi'] ?? 'Leo', tarAstro['star'] ?? 'Magha'),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 40),

                    // Circular ring score compatibility
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  value: score / 36.0,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white12,
                                  color: PremiumTheme.goldAccent,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$score',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: PremiumTheme.goldAccent,
                                    ),
                                  ),
                                  Text(
                                    '/ 36 Points',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: PremiumTheme.textSilver,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            score >= 18 ? 'Highly Compatible Match! 💍' : 'Moderate Compatibility',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: PremiumTheme.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Categories Breakdown Table
              Text(
                'Ashtakoota Breakdown',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Table(
                  border: TableBorder.symmetric(inside: const BorderSide(color: Colors.white10)),
                  children: [
                    _buildTableHeader(),
                    ...breakdown.entries.map((entry) {
                      final maxVal = _getMaxPoints(entry.key);
                      return _buildTableRow(entry.key, maxVal.toString(), entry.value.toString());
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Gemini guidance interpretation (can be blurred if locked)
              Text(
                'Cosmic Guidance Report',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),

              // Blurrable text panel
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: PremiumTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      _matchDetails!['report'] ?? '',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textSilver,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // If locked, render frosted glass overlay
                  if (!isUnlocked)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: PremiumTheme.goldAccent, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'Detailed Cosmic Report Locked',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: PremiumTheme.textWhite,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Unlock using 1 Rose',
                                  style: GoogleFonts.inter(
                                    color: PremiumTheme.textSilver,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: PremiumTheme.goldGradient,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _unlockAstro,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Text(
                                      'Unlock now 🌹',
                                      style: GoogleFonts.outfit(
                                        color: PremiumTheme.primaryBgBlack,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAstroNode(String name, String rasi, String star) {
    return Column(
      children: [
        Text(
          name,
          style: GoogleFonts.inter(fontSize: 14, color: PremiumTheme.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          rasi,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: PremiumTheme.goldLight,
          ),
        ),
        Text(
          star,
          style: GoogleFonts.inter(fontSize: 13, color: PremiumTheme.textSilver),
        ),
      ],
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white10),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Koota Category', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: PremiumTheme.goldAccent)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Max Points', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Earned Points', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: PremiumTheme.textWhite)),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String maxVal, String val) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(label, style: GoogleFonts.inter(color: PremiumTheme.textSilver)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(maxVal, style: GoogleFonts.inter(color: PremiumTheme.textSilver)),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            val, 
            style: GoogleFonts.inter(
              color: val == '0' ? PremiumTheme.crimsonRed : PremiumTheme.goldAccent, 
              fontWeight: FontWeight.bold
            )
          ),
        ),
      ],
    );
  }

  int _getMaxPoints(String category) {
    switch (category) {
      case 'Nadi': return 8;
      case 'Bhakoot': return 7;
      case 'Gana': return 6;
      case 'Maitri': return 5;
      case 'Yoni': return 4;
      case 'Tara': return 3;
      case 'Vasya': return 2;
      case 'Varna': return 1;
      default: return 0;
    }
  }
}
