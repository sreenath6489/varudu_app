import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/premium_theme.dart';

class AestheticBackground extends StatefulWidget {
  final Widget child;
  final String verticalText;

  const AestheticBackground({
    super.key,
    required this.child,
    required this.verticalText,
  });

  @override
  State<AestheticBackground> createState() => _AestheticBackgroundState();
}

class _AestheticBackgroundState extends State<AestheticBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFFF9F6F0),
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: PremiumTheme.primaryBgLight,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Warm Beige Liquid Silk Flow Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: BeigeSilkPainter(time: _controller.value),
                );
              },
            ),
          ),

          // 2. Ambient Golden Sparkles / Dust Floating Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: GoldenDustPainter(time: _controller.value),
                );
              },
            ),
          ),

          // 3. Large Vertical Background Watermark Text
          Positioned(
            left: isTablet ? 16 : -20,
            top: size.height * 0.45,
            child: IgnorePointer(
              child: RotatedBox(
                quarterTurns: 3,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Soft Sand Glow
                    Text(
                      widget.verticalText,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: isTablet ? 130 : 92,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFC49339).withOpacity(0.04),
                        height: 1.0,
                        letterSpacing: -0.04,
                      ),
                    ),
                    // Main styled text shifted slightly
                    Positioned(
                      left: 3,
                      top: 3,
                      child: Text(
                        widget.verticalText,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: isTablet ? 110 : 82,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF8A6D47).withOpacity(0.05),
                          height: 1.0,
                          letterSpacing: -0.04,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Page Contents
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Warm Beige & Sand Liquid Silk Flow
class BeigeSilkPainter extends CustomPainter {
  final double time;

  BeigeSilkPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Solid warm ivory base
    final bgPaint = Paint()..color = const Color(0xFFFAF7F2);
    canvas.drawRect(rect, bgPaint);

    // Wave 1: Warm Sand Champagne Silk
    final wave1Path = Path();
    final y1 = size.height * 0.42 + math.sin(time * math.pi * 2 + 1.0) * 40;
    wave1Path.moveTo(0, size.height);
    wave1Path.lineTo(0, y1);
    
    final controlX1 = size.width * 0.35 + math.cos(time * math.pi * 2) * 55;
    final controlY1 = size.height * 0.28 + math.sin(time * math.pi * 2) * 65;
    final controlX2 = size.width * 0.72 - math.sin(time * math.pi * 2) * 55;
    final controlY2 = size.height * 0.58 + math.cos(time * math.pi * 2) * 45;
    
    wave1Path.cubicTo(controlX1, controlY1, controlX2, controlY2, size.width, size.height * 0.48);
    wave1Path.lineTo(size.width, size.height);
    wave1Path.close();

    final wave1Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFF0E5D3).withOpacity(0.55),
          const Color(0xFFE8DAC4).withOpacity(0.40),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawPath(wave1Path, wave1Paint);

    // Wave 2: Soft Radiant Warm Ivory Glow
    final wave2Path = Path();
    final y2 = size.height * 0.22 + math.cos(time * math.pi * 2 + 0.5) * 40;
    wave2Path.moveTo(0, 0);
    wave2Path.lineTo(0, y2);

    final controlX2_1 = size.width * 0.38 - math.sin(time * math.pi * 2 + 1.2) * 55;
    final controlY2_1 = size.height * 0.38 + math.cos(time * math.pi * 2 + 0.8) * 45;
    final controlX2_2 = size.width * 0.78 + math.cos(time * math.pi * 2 + 0.2) * 50;
    final controlY2_2 = size.height * 0.18 - math.sin(time * math.pi * 2) * 40;

    wave2Path.cubicTo(controlX2_1, controlY2_1, controlX2_2, controlY2_2, size.width, size.height * 0.32);
    wave2Path.lineTo(size.width, 0);
    wave2Path.close();

    final wave2Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFFFFDF9).withOpacity(0.75),
          const Color(0xFFF7EFE1).withOpacity(0.45),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);
    canvas.drawPath(wave2Path, wave2Paint);

    // Wave 3: Honey Champagne Amber Ribbon
    final wave3Path = Path();
    final startY3 = size.height * 0.62 + math.sin(time * math.pi * 2 - 0.5) * 35;
    wave3Path.moveTo(0, startY3);

    final controlX3_1 = size.width * 0.28 + math.sin(time * math.pi * 2) * 45;
    final controlY3_1 = size.height * 0.48 - math.cos(time * math.pi * 2) * 45;
    final controlX3_2 = size.width * 0.68 - math.cos(time * math.pi * 2) * 45;
    final controlY3_2 = size.height * 0.82 + math.sin(time * math.pi * 2) * 45;

    wave3Path.cubicTo(controlX3_1, controlY3_1, controlX3_2, controlY3_2, size.width, size.height * 0.66);
    wave3Path.lineTo(size.width, size.height * 0.82);
    wave3Path.cubicTo(controlX3_2, controlY3_2 + size.height * 0.08, controlX3_1, controlY3_1 + size.height * 0.08, 0, startY3 + size.height * 0.08);
    wave3Path.close();

    final wave3Paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFEBD9BD).withOpacity(0.35),
          const Color(0xFFDFCAAA).withOpacity(0.20),
          const Color(0xFFFAF2E4).withOpacity(0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawPath(wave3Path, wave3Paint);
  }

  @override
  bool shouldRepaint(covariant BeigeSilkPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

// Custom Painter for Gentle Floating Golden Dust / Ambient Sparkles
class GoldenDustPainter extends CustomPainter {
  final double time;

  GoldenDustPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final particleCount = 18;
    final rand = math.Random(42); // Fixed seed for reproducible particles

    for (int i = 0; i < particleCount; i++) {
      final baseX = rand.nextDouble();
      final baseY = rand.nextDouble();
      final radius = 1.2 + rand.nextDouble() * 2.2;
      final speed = 0.5 + rand.nextDouble() * 1.0;
      final phase = rand.nextDouble() * math.pi * 2;

      // Vertical drift upward with wrap around
      final currentY = ((baseY - (time * speed)) % 1.0) * size.height;
      // Slight horizontal sine sway
      final currentX = (baseX * size.width) + math.sin(time * math.pi * 2 + phase) * 15;

      // Pulsing opacity
      final pulse = (math.sin(time * math.pi * 4 + phase) + 1.0) / 2.0;
      final alpha = (0.15 + pulse * 0.35);

      final paint = Paint()
        ..color = const Color(0xFFD4A853).withOpacity(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(currentX, currentY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GoldenDustPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
