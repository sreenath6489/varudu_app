import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/discover_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import 'astro_match_screen.dart';
import '../widgets/aesthetic_background.dart';
import '../widgets/glassmorphic_container.dart';

enum ViewMode { stack, reels }

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  ViewMode _currentMode = ViewMode.reels;
  final AppinioSwiperController _swiperController = AppinioSwiperController();
  final Map<String, int> _photoCarouselIndices = {};
  
  // Custom PageController for Reels vertical swiping
  late PageController _pageController;
  late FocusNode _focusNode;
  bool _isPageAnimating = false;
  int _currentReelIndex = 0;
  
  // Drag state trackers for pure Apple-style touch snapping
  double _dragStartY = 0;
  double _currentScrollOffset = 0;
  bool _dragActive = false;

  // Double-tap heart animation states
  bool _showHeartPop = false;
  String _activeHeartProfileId = '';
  Offset _lastTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _focusNode = FocusNode();
    Future.microtask(() => ref.read(discoverProvider.notifier).fetchMatches());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goToNextPage(int maxCount) {
    if (_isPageAnimating || !_pageController.hasClients) return;
    if (_currentReelIndex >= maxCount - 1) return;
    
    _isPageAnimating = true;
    _currentReelIndex++;
    _pageController.animateToPage(
      _currentReelIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) => _isPageAnimating = false);
  }

  void _goToPrevPage() {
    if (_isPageAnimating || !_pageController.hasClients) return;
    if (_currentReelIndex <= 0) return;
    
    _isPageAnimating = true;
    _currentReelIndex--;
    _pageController.animateToPage(
      _currentReelIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) => _isPageAnimating = false);
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

      final profiles = ref.read(discoverProvider).profiles;
      final profileName = profiles.firstWhere((p) => p['id'] == targetId, orElse: () => {'name': 'User'})['name'];

      if (res['match'] == true) {
        _showMatchDialog(profileName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'rose' ? 'Premium Rose Swipe Sent! 🌹' : 'Liked $profileName!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: PremiumTheme.goldAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: const TextStyle(color: Colors.white)),
          backgroundColor: PremiumTheme.crimsonRed,
        ),
      );
    }
  }

  void _showMatchDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: PremiumTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: PremiumTheme.goldBorder, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: PremiumTheme.crimsonRed, size: 72),
              const SizedBox(height: 16),
              Text(
                'It\'s a Match! 🌹',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: PremiumTheme.textWhite,
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
                child: Container(
                  decoration: BoxDecoration(
                    gradient: PremiumTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Great!'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(Map<String, dynamic> profile) {
    final family = profile['family_details'] ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return GlassmorphicContainer(
              borderRadius: 24,
              blur: 20,
              opacity: 0.85,
              padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 24),
              child: SingleChildScrollView(
                controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: PremiumTheme.goldBorder,
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
                                  fontSize: 24,
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
                                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: PremiumTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: PremiumTheme.goldAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AstroMatchScreen(targetUser: profile),
                              ),
                            );
                          },
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                          label: const Text('Astro Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    ],
                  ),
                  const Divider(color: PremiumTheme.goldBorder, height: 32),

                  Text(
                    'Astrological Coordinates',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
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

                  Text(
                    'Cultural & Professional Details',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
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
            ),
          );
        },
      );
    },
  );
}

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 14)),
          Text(value, style: GoogleFonts.inter(color: PremiumTheme.textWhite, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AestheticBackground(
        verticalText: 'DISCOVER',
        child: Stack(
          children: [
            // Profiles matcher stack / reels
            Positioned.fill(
              child: discoverState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
                  : discoverState.errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            discoverState.errorMessage,
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        )
                      : discoverState.profiles.isEmpty
                          ? _buildEmptyState()
                          : _currentMode == ViewMode.reels
                              ? _buildReelsView(discoverState.profiles)
                              : _buildStackView(discoverState.profiles),
            ),

            if (Navigator.of(context).canPop())
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: PremiumTheme.goldBorder),
                          boxShadow: const [
                            BoxShadow(color: Color(0x144A3728), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: PremiumTheme.darkEspresso, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? PremiumTheme.goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [BoxShadow(color: PremiumTheme.goldAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : PremiumTheme.textSilver,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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
          Icon(Icons.favorite_border_rounded, size: 64, color: PremiumTheme.goldAccent.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No profiles found',
            style: GoogleFonts.inter(
              fontSize: 20,
              color: PremiumTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for new profiles',
            style: GoogleFonts.inter(color: PremiumTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Reels View Mode (Vertical Swiper PageView with custom Apple Snapping & keyboard/trackpad control)
  Widget _buildReelsView(List<dynamic> profiles) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _goToNextPage(profiles.length);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _goToPrevPage();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final dy = pointerSignal.scrollDelta.dy;
            if (dy > 15) {
              _goToNextPage(profiles.length);
            } else if (dy < -15) {
              _goToPrevPage();
            }
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (details) {
            if (!_pageController.hasClients || _isPageAnimating) return;
            _dragStartY = details.globalPosition.dy;
            _currentScrollOffset = _pageController.offset;
            _dragActive = true;
          },
          onVerticalDragUpdate: (details) {
            if (!_dragActive || !_pageController.hasClients) return;
            final deltaY = _dragStartY - details.globalPosition.dy;
            
            double targetOffset = _currentScrollOffset + deltaY;
            final maxOffset = _pageController.position.maxScrollExtent;
            if (targetOffset < 0) {
              targetOffset = targetOffset * 0.3; // Resist sliding out of bounds at top
            } else if (targetOffset > maxOffset) {
              targetOffset = maxOffset + (targetOffset - maxOffset) * 0.3; // Resist sliding out of bounds at bottom
            }
            
            _pageController.position.correctPixels(targetOffset);
            _pageController.position.notifyListeners();
          },
          onVerticalDragEnd: (details) {
            if (!_dragActive || !_pageController.hasClients) return;
            _dragActive = false;
            
            final pageHeight = _pageController.position.viewportDimension;
            final dragDeltaY = _dragStartY - details.globalPosition.dy;
            final velocity = details.primaryVelocity ?? 0;
            
            int targetPage = _currentReelIndex;
            if (velocity < -250 || dragDeltaY > pageHeight * 0.22) {
              targetPage = _currentReelIndex + 1;
            } else if (velocity > 250 || dragDeltaY < -pageHeight * 0.22) {
              targetPage = _currentReelIndex - 1;
            }
            
            targetPage = targetPage.clamp(0, profiles.length - 1);
            
            _isPageAnimating = true;
            _currentReelIndex = targetPage;
            _pageController.animateToPage(
              _currentReelIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ).then((_) => _isPageAnimating = false);
          },
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Blocks default trackpad scroll page-skipping
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

              return Center(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 74, 16, 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x303E2D20),
                        blurRadius: 28,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Expanded photo image
                        Positioned.fill(
                          child: Listener(
                            onPointerDown: (event) {
                              _lastTapPosition = event.localPosition;
                            },
                            child: GestureDetector(
                              onTap: () {
                                final cardWidth = MediaQuery.of(context).size.width;
                                final tapX = _lastTapPosition.dx;
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
                              child: _buildProfileImage(activePhotoUrl),
                            ),
                          ),
                        ),

                        // Vignette bottom gradient
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Color(0x33000000),
                                  Color(0xD9000000),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.0, 0.45, 0.70, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Carousel indicators if multiple photos
                        if (photos.length > 1)
                          Positioned(
                            top: 14,
                            left: 16,
                            right: 16,
                            child: Row(
                              children: List.generate(photos.length, (idx) {
                                return Expanded(
                                  child: Container(
                                    height: 3,
                                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                    decoration: BoxDecoration(
                                      color: idx == photoIdx ? Colors.white : Colors.white24,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                        // Double tap heart pop
                        if (_showHeartPop && _activeHeartProfileId == profile['id'])
                          const Center(child: PulsingHeartAnimation()),

                        // Bottom-Left text details (Matching Image 2)
                        Positioned(
                          left: 18,
                          bottom: 20,
                          right: 76,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${profile['name']}, ${profile['age']}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                  shadows: const [
                                    Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.85), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile['city'] ?? 'Tirupati',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '✦ DOUBLE-CLICK IMAGE TO LIKE',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom-Right vertical buttons (Matching Image 2)
                        Positioned(
                          right: 14,
                          bottom: 20,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Info button
                              _buildFrostedActionBtn(
                                icon: Icons.info_outline_rounded,
                                onTap: () => _showDetailsSheet(profile),
                              ),
                              const SizedBox(height: 10),
                              // Pass button
                              _buildFrostedActionBtn(
                                icon: Icons.close_rounded,
                                onTap: () => _handleSwipeAction(profile['id'], 'rejected'),
                              ),
                              const SizedBox(height: 10),
                              // Like button (White circle with Black Heart)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeHeartProfileId = profile['id'];
                                    _showHeartPop = true;
                                  });
                                  _handleSwipeAction(profile['id'], 'accepted');
                                  Future.delayed(const Duration(milliseconds: 800), () {
                                    if (mounted) setState(() => _showHeartPop = false);
                                  });
                                },
                                child: Container(
                                  height: 46,
                                  width: 46,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.black,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Rose button
                              GestureDetector(
                                onTap: () => _handleSwipeAction(profile['id'], 'accepted', type: 'rose'),
                                child: Container(
                                  height: 38,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('🌹', style: TextStyle(fontSize: 18)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String photoUrl) {
    if (photoUrl.isEmpty) {
      return _buildReelsPlaceholder();
    }
    if (photoUrl.startsWith('assets/')) {
      return Image.asset(photoUrl, fit: BoxFit.cover);
    }
    final fullUrl = photoUrl.startsWith('http') ? photoUrl : '${ApiService.baseUrl}$photoUrl';
    return CachedNetworkImage(
      imageUrl: fullUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: PremiumTheme.goldAccent),
      ),
      errorWidget: (context, url, err) => _buildReelsPlaceholder(),
    );
  }

  Widget _buildReelsPlaceholder() {
    return Container(
      color: const Color(0xFFE8DFD3),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 80, color: Color(0xFFC59B4E)),
      ),
    );
  }

  Widget _buildFrostedActionBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.0),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _buildReelsBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return _buildFrostedActionBtn(icon: icon, onTap: onTap);
  }

  // Stack Swiper View Mode (Tinder Cards)
  Widget _buildStackView(List<dynamic> profiles) {
    return Container(
      padding: const EdgeInsets.only(top: 130, bottom: 40),
      alignment: Alignment.center,
      child: AppinioSwiper(
        controller: _swiperController,
        cardCount: profiles.length,
        onSwipeEnd: (previousIndex, targetIndex, activity) {
          final idx = previousIndex - 1;
          if (idx >= 0 && idx < profiles.length) {
            final target = profiles[idx];
            if (activity.direction == AxisDirection.right) {
              _handleSwipeAction(target['id'], 'accepted');
            } else {
              _handleSwipeAction(target['id'], 'rejected');
            }
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
              border: Border.all(color: PremiumTheme.goldBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6E522E).withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTapDown: (details) {
                      final cardWidth = MediaQuery.of(context).size.width - 64;
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
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent)),
                            errorWidget: (context, url, err) => _buildReelsPlaceholder(),
                          )
                        : _buildReelsPlaceholder(),
                  ),

                  // Dark overlay gradient
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black87],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Photo index dots
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
                                color: idx == photoIdx ? Colors.white : Colors.white24,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Profile info overlay
                  Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${profile['name']}, ${profile['age']}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (profile['face_verified'] == true)
                              const Icon(Icons.verified, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              profile['city'] ?? 'Location N/A',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                profile['family_details']?['star'] ?? 'Star N/A',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),

                            TextButton.icon(
                              onPressed: () => _showDetailsSheet(profile),
                              icon: const Icon(Icons.info_outline_rounded, color: PremiumTheme.goldBright, size: 16),
                              label: Text(
                                'View Profile Info',
                                style: GoogleFonts.inter(color: PremiumTheme.goldBright, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
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
          color: Colors.white,
          size: 110,
          shadows: [
            Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 4)),
          ],
        ),
      ),
    );
  }
}

