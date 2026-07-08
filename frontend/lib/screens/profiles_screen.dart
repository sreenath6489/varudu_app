import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/discover_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import 'astro_match_screen.dart';

enum ViewMode { stack, reels }

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  ViewMode _currentMode = ViewMode.reels;
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  
  // Carousel photo indices mapped by profile ID
  final Map<String, int> _photoCarouselIndices = {};

  // Double-tap heart animation states
  bool _showHeartPop = false;
  String _activeHeartProfileId = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(discoverProvider.notifier).fetchMatches());
  }

  int _getPhotoIndex(String profileId) {
    return _photoCarouselIndices[profileId] ?? 0;
  }

  void _setPhotoIndex(String profileId, int index, int maxPhotos) {
    if (maxPhotos == 0) return;
    int next = index;
    if (next < 0) next = maxPhotos - 1;
    if (next >= maxPhotos) next = 0;
    setState(() {
      _photoCarouselIndices[profileId] = next;
    });
  }

  Future<void> _handleSwipeAction(String targetId, String status, {String type = 'standard'}) async {
    try {
      final res = await ref.read(discoverProvider.notifier).swipe(
        targetId: targetId,
        status: status,
        interactionType: type,
      );

      final profileName = ref.read(discoverProvider).profiles.firstWhere((p) => p['id'] == targetId, orElse: () => {'name': 'User'})['name'];

      if (res['match'] == true) {
        _showMatchDialog(profileName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'rose' ? 'Premium Rose Swipe Sent! 🌹' : 'Liked $profileName!'),
            backgroundColor: PremiumTheme.goldAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
    }
  }

  void _showMatchDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PremiumTheme.goldAccent, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: PremiumTheme.crimsonRed, size: 72),
              const SizedBox(height: 16),
              Text(
                'It\'s a Match! 🌹',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You and $name have expressed mutual interest. Start chatting to know each other!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.goldAccent,
                    foregroundColor: PremiumTheme.primaryBgBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Great!'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Display details bottom sheet
  void _showDetailsSheet(Map<String, dynamic> profile) {
    final family = profile['family_details'] ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${profile['name']}, ${profile['age']}',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: PremiumTheme.textWhite,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (profile['face_verified'] == true)
                                const Icon(Icons.verified, color: PremiumTheme.goldAccent, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: PremiumTheme.goldAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                profile['city'] ?? 'Location N/A',
                                style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Ashtakoota compatibility launcher button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AstroMatchScreen(targetUser: profile),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text('Astro Match'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumTheme.goldAccent,
                          foregroundColor: PremiumTheme.primaryBgBlack,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 32),

                  // Section Horoscope details
                  Text(
                    'Astrological Coordinates',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: PremiumTheme.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Time of Birth (TOB)', profile['tob'] ?? 'N/A'),
                  _buildDetailRow('Place of Birth (POB)', profile['pob'] ?? 'N/A'),
                  _buildDetailRow('Rasi (Moon Sign)', family['rasi'] ?? 'N/A'),
                  _buildDetailRow('Nakshatram (Star)', family['star'] ?? 'N/A'),
                  _buildDetailRow('Gothram', family['gothram'] ?? 'N/A'),

                  const SizedBox(height: 24),

                  // Section Cultural details
                  Text(
                    'Cultural & Professional Details',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: PremiumTheme.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Sub-caste', family['subCaste'] ?? 'N/A'),
                  _buildDetailRow('Education', family['education'] ?? 'N/A'),
                  _buildDetailRow('Occupation', family['occupation'] ?? 'N/A'),
                  _buildDetailRow('Family Status', family['family_status'] ?? 'N/A'),
                  
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 14)),
          Text(value, style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider);

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgBlack,
      body: Stack(
        children: [
          // Profiles matcher stack / reels
          Positioned.fill(
            child: discoverState.isLoading
                ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
                : discoverState.errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          discoverState.errorMessage,
                          style: GoogleFonts.inter(color: PremiumTheme.crimsonRed),
                        ),
                      )
                    : discoverState.profiles.isEmpty
                        ? _buildEmptyState()
                        : _currentMode == ViewMode.reels
                            ? _buildReelsView(discoverState.profiles)
                            : _buildStackView(discoverState.profiles),
          ),

          // Header segmented control toggles
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: PremiumTheme.textWhite,
                        size: 22,
                      ),
                    ),
                  ),

                  // Segmented control toggle
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeToggle(ViewMode.stack, 'STACK'),
                        _buildModeToggle(ViewMode.reels, 'REELS'),
                      ],
                    ),
                  ),

                  const SizedBox(width: 46), // Align center balance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ViewMode mode, String label) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? PremiumTheme.primaryBgBlack : PremiumTheme.textSilver,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.heart_broken_outlined, size: 64, color: PremiumTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No matching profiles found',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              color: PremiumTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try updating your preference settings',
            style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Reels Full screen Vertical View Mode
  Widget _buildReelsView(List<dynamic> profiles) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final photos = profile['photos'] as List<dynamic>? ?? [];
        final photoIdx = _getPhotoIndex(profile['id']);
        final hasPhotos = photos.isNotEmpty;
        
        String activePhotoUrl = '';
        if (hasPhotos) {
          final relative = photos[photoIdx];
          activePhotoUrl = relative.startsWith('http') ? relative : '${ApiService.baseUrl}$relative';
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Tap Zone Photo Carousel navigation
            GestureDetector(
              onTapDown: (details) {
                final cardWidth = MediaQuery.of(context).size.width;
                final tapX = details.localPosition.dx;
                if (tapX < cardWidth * 0.33) {
                  _setPhotoIndex(profile['id'], photoIdx - 1, photos.length);
                } else {
                  _setPhotoIndex(profile['id'], photoIdx + 1, photos.length);
                }
              },
              onDoubleTap: () {
                setState(() {
                  _activeHeartProfileId = profile['id'];
                  _showHeartPop = true;
                });
                _handleSwipeAction(profile['id'], 'accepted');
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) setState(() => _showHeartPop = false);
                });
              },
              child: hasPhotos
                  ? CachedNetworkImage(
                      imageUrl: activePhotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, err) => _buildReelsPlaceholder(),
                    )
                  : _buildReelsPlaceholder(),
            ),

            // Shading Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.25, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Top Carousel Navigation Bars (Instagram style)
            if (photos.length > 1)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(photos.length, (idx) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          color: idx == photoIdx ? PremiumTheme.goldAccent : Colors.white24,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Double tap pulsing heart overlay
            if (_showHeartPop && _activeHeartProfileId == profile['id'])
              const Center(child: PulsingHeartAnimation()),

            // Bio Metadata (Bottom-Left)
            Positioned(
              left: 20,
              bottom: 40,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${profile['name']}, ${profile['age']}',
                        style: GoogleFonts.cormorantGaramond(
                          color: PremiumTheme.textWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (profile['face_verified'] == true)
                        const Icon(Icons.verified, color: PremiumTheme.goldAccent, size: 22),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: PremiumTheme.goldAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        profile['city'] ?? 'Location N/A',
                        style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Gothram / Star highlights
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          profile['family_details']?['star'] ?? 'Star N/A',
                          style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          profile['family_details']?['rasi'] ?? 'Rasi N/A',
                          style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Reels Action Buttons Tray (Right-Side floating menu)
            Positioned(
              right: 16,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Info Sheet button
                  _buildReelsBtn(
                    icon: Icons.info_outline_rounded,
                    color: PremiumTheme.textWhite,
                    onTap: () => _showDetailsSheet(profile),
                  ),
                  const SizedBox(height: 16),

                  // Swipe left pass button
                  _buildReelsBtn(
                    icon: Icons.close_rounded,
                    color: PremiumTheme.textMuted,
                    onTap: () => _handleSwipeAction(profile['id'], 'rejected'),
                  ),
                  const SizedBox(height: 16),

                  // Swipe right standard like button
                  _buildReelsBtn(
                    icon: Icons.favorite_rounded,
                    color: PremiumTheme.crimsonRed,
                    onTap: () => _handleSwipeAction(profile['id'], 'accepted'),
                  ),
                  const SizedBox(height: 16),

                  // Premium Rose swipe button
                  GestureDetector(
                    onTap: () => _handleSwipeAction(profile['id'], 'accepted', type: 'rose'),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🌹', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildReelsPlaceholder() {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 100, color: Colors.white12),
      ),
    );
  }

  Widget _buildReelsBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  // Mode A: Tinder AppinioSwiper Card Stack View
  Widget _buildStackView(List<dynamic> profiles) {
    return Container(
      padding: const EdgeInsets.only(top: 130, bottom: 40),
      alignment: Alignment.center,
      child: AppinioSwiper(
        controller: _swiperController,
        cardCount: profiles.length,
        onSwipeEnd: (previousIndex, targetIndex, activity) {
          final target = profiles[previousIndex];
          if (activity.direction == AxisDirection.right) {
            _handleSwipeAction(target['id'], 'accepted');
          } else {
            _handleSwipeAction(target['id'], 'rejected');
          }
        },
        cardBuilder: (context, index) {
          final profile = profiles[index];
          final photos = profile['photos'] as List<dynamic>? ?? [];
          final photoIdx = _getPhotoIndex(profile['id']);
          final hasPhotos = photos.isNotEmpty;
          
          String activePhotoUrl = '';
          if (hasPhotos) {
            final relative = photos[photoIdx];
            activePhotoUrl = relative.startsWith('http') ? relative : '${ApiService.baseUrl}$relative';
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: PremiumTheme.surfaceCard,
              border: Border.all(color: Colors.white12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTapDown: (details) {
                      final cardWidth = MediaQuery.of(context).size.width - 64; // Approx card width
                      final tapX = details.localPosition.dx;
                      if (tapX < cardWidth * 0.33) {
                        _setPhotoIndex(profile['id'], photoIdx - 1, photos.length);
                      } else {
                        _setPhotoIndex(profile['id'], photoIdx + 1, photos.length);
                      }
                    },
                    child: hasPhotos
                        ? CachedNetworkImage(
                            imageUrl: activePhotoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, err) => _buildReelsPlaceholder(),
                          )
                        : _buildReelsPlaceholder(),
                  ),

                  // Bottom metadata details overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${profile['name']}, ${profile['age']}',
                                style: GoogleFonts.cormorantGaramond(
                                  color: PremiumTheme.textWhite,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (profile['face_verified'] == true)
                                const Icon(Icons.verified, color: PremiumTheme.goldAccent, size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: PremiumTheme.goldAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                profile['city'] ?? 'Location N/A',
                                style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Quick Info badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  profile['family_details']?['star'] ?? 'Star N/A',
                                  style: GoogleFonts.inter(color: PremiumTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),

                              // Quick Details sheet trigger
                              TextButton(
                                onPressed: () => _showDetailsSheet(profile),
                                child: Text(
                                  'View Profile Info',
                                  style: GoogleFonts.inter(color: PremiumTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Indicator bars
                  if (photos.length > 1)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: List.generate(photos.length, (idx) {
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2.0),
                              decoration: BoxDecoration(
                                color: idx == photoIdx ? PremiumTheme.goldAccent : Colors.white24,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Double tap heart pop animation widget
class PulsingHeartAnimation extends StatefulWidget {
  const PulsingHeartAnimation({super.key});

  @override
  State<PulsingHeartAnimation> createState() => _PulsingHeartAnimationState();
}

class _PulsingHeartAnimationState extends State<PulsingHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.linear));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: const Icon(
          Icons.favorite_rounded,
          color: PremiumTheme.crimsonRed,
          size: 110,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 4)),
          ],
        ),
      ),
    );
  }
}
