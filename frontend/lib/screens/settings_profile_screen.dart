import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';

class SettingsProfileScreen extends ConsumerStatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  ConsumerState<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends ConsumerState<SettingsProfileScreen> {
  final _aadhaarController = TextEditingController();

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  void _triggerAadhaarVerify() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceCard,
        title: Text('Aadhaar Verification', style: GoogleFonts.cormorantGaramond(color: PremiumTheme.goldAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your 12-digit Aadhaar number for mock OTP check:', style: GoogleFonts.inter(color: PremiumTheme.textSilver)),
            const SizedBox(height: 12),
            TextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '0000 0000 0000',
                hintStyle: TextStyle(color: PremiumTheme.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: PremiumTheme.goldAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: PremiumTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final num = _aadhaarController.text.trim();
              if (num.length >= 12) {
                final success = await ref.read(authProvider.notifier).verifyAadhaar(num);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aadhaar Verified Successfully!'), backgroundColor: PremiumTheme.activeBlue),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.goldAccent, foregroundColor: Colors.black),
            child: const Text('Verify'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile ?? {};
    final photos = profile['photos'] as List<dynamic>? ?? [];
    final hasPhoto = photos.isNotEmpty;
    
    final isAadhaarVerified = profile['aadhaar_verified'] == true;
    final isFaceVerified = profile['face_verified'] == true;
    final isPhoneVisible = profile['phone_visible'] == true;

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile header card
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.goldAccent, width: 2),
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? CachedNetworkImage(
                                imageUrl: photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, err) => Container(color: Colors.grey.shade900),
                              )
                            : Container(color: Colors.grey.shade900),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profile['name'] ?? 'User Name',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: PremiumTheme.textWhite,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (isFaceVerified)
                          const Icon(Icons.verified, color: PremiumTheme.goldAccent, size: 20),
                      ],
                    ),
                    Text(
                      profile['email'] ?? '',
                      style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Verification Checklist Cards
              Text(
                'Trust & Verifications',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    // Aadhaar Verification status
                    ListTile(
                      leading: Icon(
                        isAadhaarVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        color: isAadhaarVerified ? PremiumTheme.activeBlue : PremiumTheme.textMuted,
                      ),
                      title: Text('Aadhaar Verified Badge', style: GoogleFonts.inter(color: PremiumTheme.textWhite)),
                      subtitle: Text(
                        isAadhaarVerified ? 'Identity verified successfully' : 'Provide Aadhaar to gain trust score',
                        style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
                      ),
                      trailing: isAadhaarVerified
                          ? const Icon(Icons.verified, color: PremiumTheme.activeBlue)
                          : TextButton(
                              onPressed: _triggerAadhaarVerify,
                              child: Text('Verify Now', style: GoogleFonts.inter(color: PremiumTheme.goldAccent)),
                            ),
                    ),
                    const Divider(color: Colors.white10),

                    // Selfie Face Verification status
                    ListTile(
                      leading: Icon(
                        isFaceVerified ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                        color: isFaceVerified ? PremiumTheme.activeBlue : PremiumTheme.textMuted,
                      ),
                      title: Text('Face Verification Selfie', style: GoogleFonts.inter(color: PremiumTheme.textWhite)),
                      subtitle: Text(
                        isFaceVerified ? 'Facial features verified via Rekognition' : 'Take live selfie comparison check',
                        style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
                      ),
                      trailing: isFaceVerified
                          ? const Icon(Icons.verified, color: PremiumTheme.goldAccent)
                          : const Icon(Icons.lock_clock_outlined, color: Colors.white24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Visibility settings controls
              Text(
                'Visibility Configurations',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: SwitchListTile(
                  value: isPhoneVisible,
                  onChanged: (val) {
                    ref.read(authProvider.notifier).togglePhoneVisibility(val);
                  },
                  activeColor: PremiumTheme.goldAccent,
                  inactiveThumbColor: PremiumTheme.textMuted,
                  inactiveTrackColor: Colors.black38,
                  title: Text('Phone Visibility', style: GoogleFonts.inter(color: PremiumTheme.textWhite)),
                  subtitle: Text(
                    'Allow mutual matches to request or view your phone number (requires Rose unlock)',
                    style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Photos Grid
              Text(
                'Your Profile Gallery',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              if (photos.isEmpty)
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text('No photos uploaded yet.', style: TextStyle(color: Colors.grey.shade600)),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photoUrl = photos[index].startsWith('http') ? photos[index] : '${ApiService.baseUrl}${photos[index]}';
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: PremiumTheme.surfaceCard),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 48),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: PremiumTheme.crimsonRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
