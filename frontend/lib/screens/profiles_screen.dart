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
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  void _showMatchDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.black, size: 72),
              const SizedBox(height: 16),
              Text(
                'It\'s a Match! 🌹',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You and $name have expressed mutual interest. Start chatting to know each other!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showDetailsSheet(Map<String, dynamic> profile) {
    final family = profile['family_details'] ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        color: Colors.grey.shade300,
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
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (profile['face_verified'] == true)
                                const Icon(Icons.verified, color: Colors.black, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.black, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                profile['city'] ?? 'Location N/A',
                                style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AstroMatchScreen(targetUser: profile),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                        label: const Text('Astro Match', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    ],
                  ),
                  const Divider(color: Colors.black12, height: 32),

                  Text(
                    'Astrological Coordinates',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: GoogleFonts.inter(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Profiles matcher stack / reels
          Positioned.fill(
            child: discoverState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
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

          // Header segmented control toggles (Minimalist Apple Style)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),

                    // Segmented control toggle
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeToggle(ViewMode.stack, 'STACK'),
                          _buildModeToggle(ViewMode.reels, 'REELS'),
                        ],
                      ),
                    ),

                    const SizedBox(width: 40), // Align center balance
                  ],
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
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
          const Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No profiles found',
            style: GoogleFonts.inter(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for new profiles',
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
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

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Expanded full screen photo image
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
                        child: hasPhotos
                            ? CachedNetworkImage(
                                imageUrl: activePhotoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.black)),
                                errorWidget: (context, url, err) => _buildReelsPlaceholder(),
                              )
                            : _buildReelsPlaceholder(),
                      ),
                    ),
                  ),

                  // Subtle dark overlay gradient at the bottom for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black38,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black54,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.2, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Carousel navigation indicators
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
                                color: idx == photoIdx ? Colors.white : Colors.white24,
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

                  // Bio Metadata Details (Bottom-Left)
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
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [const Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 1))],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (profile['face_verified'] == true)
                              const Icon(Icons.verified, color: Colors.white, size: 22),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              profile['city'] ?? 'Location N/A',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                shadows: [const Shadow(color: Colors.black87, blurRadius: 8)],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Astro quick info tags
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text(
                                profile['family_details']?['star'] ?? 'Star N/A',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Text(
                                profile['family_details']?['rasi'] ?? 'Rasi N/A',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons Tray (Right-Side floating menu)
                  Positioned(
                    right: 16,
                    bottom: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildReelsBtn(
                          icon: Icons.info_outline_rounded,
                          color: Colors.white,
                          onTap: () => _showDetailsSheet(profile),
                        ),
                        const SizedBox(height: 16),
                        _buildReelsBtn(
                          icon: Icons.close_rounded,
                          color: Colors.white,
                          onTap: () => _handleSwipeAction(profile['id'], 'rejected'),
                        ),
                        const SizedBox(height: 16),
                        _buildReelsBtn(
                          icon: Icons.favorite_rounded,
                          color: Colors.white,
                          onTap: () => _handleSwipeAction(profile['id'], 'accepted'),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _handleSwipeAction(profile['id'], 'accepted', type: 'rose'),
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🌹', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReelsPlaceholder() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.person_rounded, size: 80, color: Colors.black12),
      ),
    );
  }

  Widget _buildReelsBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 22),
      ),
    );
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
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
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
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.black)),
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

                            TextButton(
                              onPressed: () => _showDetailsSheet(profile),
                              child: Text(
                                'View Profile Info',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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

