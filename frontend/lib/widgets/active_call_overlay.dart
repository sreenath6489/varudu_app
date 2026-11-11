import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../theme/premium_theme.dart';

class ActiveCallOverlay extends StatefulWidget {
  final Map<String, dynamic> partner;
  final bool isIncoming;
  final String status; // 'dialing', 'ringing', 'connected', 'disconnected'
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onEnd;

  const ActiveCallOverlay({
    super.key,
    required this.partner,
    required this.isIncoming,
    required this.status,
    required this.onAccept,
    required this.onDecline,
    required this.onEnd,
  });

  @override
  State<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<ActiveCallOverlay> {
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;

  // Headless audio player for call sounds
  VideoPlayerController? _audioController;

  @override
  void initState() {
    super.initState();
    _manageCallAudio();
    if (widget.status == 'connected') {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(ActiveCallOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status || widget.isIncoming != oldWidget.isIncoming) {
      _manageCallAudio();
    }
    if (widget.status == 'connected' && oldWidget.status != 'connected') {
      _startTimer();
    } else if (widget.status != 'connected') {
      _timer?.cancel();
    }
  }

  void _manageCallAudio() {
    if (widget.status == 'dialing' || widget.status == 'ringing') {
      if (widget.isIncoming) {
        // Loop telephone ringtone
        _playSound('https://www.soundjay.com/phone/sounds/telephone-ring-03a.mp3');
      } else {
        // Loop outgoing ringback dial tone
        _playSound('https://www.soundjay.com/phone/sounds/phone-calling-1.mp3');
      }
    } else {
      _stopSound();
    }
  }

  void _playSound(String url) {
    _stopSound();
    try {
      _audioController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            _audioController?.setLooping(true);
            _audioController?.play();
          }
        });
    } catch (e) {
      debugPrint('Failed to play call audio sound: $e');
    }
  }

  void _stopSound() {
    _audioController?.pause();
    _audioController?.dispose();
    _audioController = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopSound();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.partner['photos'] as List<dynamic>? ?? [];
    final hasPhoto = photos.isNotEmpty;
    final photoUrl = hasPhoto 
        ? (photos[0].startsWith('http') ? photos[0] : '${ApiService.baseUrl}${photos[0]}')
        : '';

    return Material(
      color: const Color(0xFFF9F9FA),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background soft radial gradient instead of solid black
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFFFAF7F2), Color(0xFFF0E8DC)],
                  center: Alignment.center,
                  radius: 1.2,
                ),
              ),
            ),
          ),
          
          // Blurred background image
          if (hasPhoto)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, o, s) => const SizedBox(),
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Top header
                Column(
                  children: [
                    Text(
                      'IN-APP CALL',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.goldAccent,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.partner['name'] ?? 'User',
                      style: GoogleFonts.cormorantGaramond(
                        color: PremiumTheme.textWhite,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.status == 'connected'
                          ? _formatDuration(_seconds)
                          : widget.status == 'dialing'
                              ? 'DIALING...'
                              : 'RINGING...',
                      style: GoogleFonts.inter(
                        color: PremiumTheme.textSilver,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // Central pulsing Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing Ring Animation
                    _PulsingCallRing(),
                    
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: PremiumTheme.goldAccent, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: PremiumTheme.goldAccent.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: hasPhoto
                            ? CachedNetworkImage(
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.person, size: 70, color: Colors.black26),
                              ),
                      ),
                    ),
                  ],
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: widget.isIncoming && widget.status == 'ringing'
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Decline Button
                            _buildCallButton(
                              icon: Icons.call_end_rounded,
                              label: 'Decline',
                              color: const Color(0xFFE53935),
                              onTap: widget.onDecline,
                            ),
                            // Accept Button
                            _buildCallButton(
                              icon: Icons.phone_rounded,
                              label: 'Accept',
                              color: const Color(0xFF43A047),
                              onTap: widget.onAccept,
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Mute
                            _buildCallIconButton(
                              icon: _isMuted ? Icons.mic_off : Icons.mic,
                              onTap: () => setState(() => _isMuted = !_isMuted),
                              isActive: _isMuted,
                            ),
                            // End Call Button
                            _buildCallButton(
                              icon: Icons.call_end_rounded,
                              label: 'End Call',
                              color: const Color(0xFFE53935),
                              onTap: widget.onEnd,
                            ),
                            // Speaker
                            _buildCallIconButton(
                              icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                              onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                              isActive: _isSpeaker,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(color: PremiumTheme.textSilver, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCallIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? PremiumTheme.goldAccent : PremiumTheme.surfaceCard,
          border: Border.all(color: PremiumTheme.goldBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6E522E).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : PremiumTheme.textWhite,
          size: 24,
        ),
      ),
    );
  }
}

class _PulsingCallRing extends StatefulWidget {
  @override
  State<_PulsingCallRing> createState() => _PulsingCallRingState();
}

class _PulsingCallRingState extends State<_PulsingCallRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(2, (index) {
            final delay = index * 0.5;
            final progress = (_controller.value + delay) % 1.0;
            final size = 140.0 + (progress * 80.0);
            final opacity = (1.0 - progress) * 0.4;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PremiumTheme.goldAccent.withOpacity(opacity),
                  width: 2,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
