import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Hide status bars for immersive video splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
        _controller!.addListener(_videoListener);
      }
    }).catchError((error) {
      print('Video Splash: Failed to initialize video asset (probably missing intro.mp4): $error');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        // Automatically skip if the file is missing/corrupted to prevent app crash
        _proceedToApp();
      }
    });
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      final value = _controller!.value;
      if (value.duration > Duration.zero && value.position >= value.duration) {
        _proceedToApp();
      }
    }
  }

  void _proceedToApp() {
    // Restore status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && !_hasError)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover, // Auto crops horizontal video to cover the vertical screen
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else
            // Fallback black background with simple loader while loading or if missing
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // skip button
          if (_isInitialized && !_hasError)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: _proceedToApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
