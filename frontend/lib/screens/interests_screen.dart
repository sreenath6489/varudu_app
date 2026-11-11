import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';
import '../widgets/aesthetic_background.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  List<dynamic> _interestedProfiles = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchInterests();
  }

  Future<void> _fetchInterests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService.getInterests();
      if (!mounted) return;
      setState(() {
        _interestedProfiles = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'INTERESTS',
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            color: PremiumTheme.textWhite,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: PremiumTheme.textWhite),
      ),
      body: AestheticBackground(
        verticalText: 'INTERESTS',
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: PremiumTheme.goldAccent))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: GoogleFonts.inter(color: PremiumTheme.crimsonRed)))
                : _interestedProfiles.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: PremiumTheme.goldAccent.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: PremiumTheme.goldAccent.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: PremiumTheme.goldAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Interests Yet',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PremiumTheme.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Profiles you double-tap or send roses to on the Reels screen will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: PremiumTheme.textSilver,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.74,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _interestedProfiles.length,
      itemBuilder: (context, index) {
        final profile = _interestedProfiles[index];
        final photoUrl = profile['photoUrl'];
        final fullPhotoUrl = photoUrl != null
            ? (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')
                ? photoUrl
                : '${ApiService.baseUrl}$photoUrl')
            : null;

        return Container(
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PremiumTheme.goldBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E522E).withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Profile image
                fullPhotoUrl != null
                    ? Image.network(
                        fullPhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultPlaceholder();
                        },
                      )
                    : _buildDefaultPlaceholder(),

                // Bottom gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // Text details overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile['name']}, ${profile['age']}',
                        style: GoogleFonts.cormorantGaramond(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              profile['city'] ?? '',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Little floating heart badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: PremiumTheme.surfaceCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: PremiumTheme.goldBorder),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: PremiumTheme.crimsonRed,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: PremiumTheme.surfaceElevated,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 52,
        color: PremiumTheme.goldLight,
      ),
    );
  }
}
