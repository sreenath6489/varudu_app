import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/premium_theme.dart';

/// Recreates the signature sunlit sand wall with delicate organic foliage shadows
/// exactly as seen on varudu.in!
class AestheticBackground extends StatefulWidget {
  final Widget child;
  final String? verticalText;
  final bool showSparkleFab;
  final VoidCallback? onSparkleTap;

  const AestheticBackground({
    super.key,
    required this.child,
    this.verticalText,
    this.showSparkleFab = true,
    this.onSparkleTap,
  });

  @override
  State<AestheticBackground> createState() => _AestheticBackgroundState();
}

class _AestheticBackgroundState extends State<AestheticBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _breezeController;

  @override
  void initState() {
    super.initState();
    // Gentle natural breeze sway for the sunlit leaf shadows (10-second subtle cycle)
    _breezeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: PremiumTheme.primaryBgLight,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _breezeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base Sunlit Sand Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF7F2EB), // Warm morning sunlight
                Color(0xFFF3ECE2), // Base warm sand
                Color(0xFFEBE0D2), // Soft shaded sand depth
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // 2. Organic Tree Foliage Shadows
        AnimatedBuilder(
          animation: _breezeController,
          builder: (context, child) {
            return CustomPaint(
              painter: SunlitFoliageShadowPainter(
                sway: _breezeController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // 3. Main Child Content
        widget.child,

        // 4. Signature Floating Sparkle Button (as seen in all varudu.in screenshots)
        if (widget.showSparkleFab)
          Positioned(
            right: 20,
            bottom: 24,
            child: GestureDetector(
              onTap: widget.onSparkleTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1F4A3728),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  '✨',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the natural, soft-focus tree and foliage shadows cast across the sunlit wall
class SunlitFoliageShadowPainter extends CustomPainter {
  final double sway;

  SunlitFoliageShadowPainter({required this.sway});

  @override
  void paint(Canvas canvas, Size size) {
    final double swayOffset = (sway - 0.5) * 8.0;

    // Warm soft shadow paint (diluted sepia/umber tone)
    final shadowPaint = Paint()
      ..color = const Color(0xFF6B5848).withOpacity(0.048)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    final branchPaint = Paint()
      ..color = const Color(0xFF5A4839).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    canvas.save();
    canvas.translate(swayOffset, swayOffset * 0.5);

    // Main Branch 1 (reaching from top-left)
    final branch1 = Path()
      ..moveTo(-40, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.18,
        size.width * 0.45,
        size.height * 0.38,
      );
    canvas.drawPath(branch1, branchPaint);

    // Branch 2 (upper twig)
    final branch2 = Path()
      ..moveTo(size.width * 0.05, -30)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.15,
        size.width * 0.35,
        size.height * 0.22,
      );
    canvas.drawPath(branch2, branchPaint);

    // Leaves Cluster along Branch 1 & 2
    _drawLeaf(canvas, size.width * 0.12, size.height * 0.14, 55, 32, -0.6, shadowPaint);
    _drawLeaf(canvas, size.width * 0.18, size.height * 0.20, 68, 36, -0.4, shadowPaint);
    _drawLeaf(canvas, size.width * 0.25, size.height * 0.16, 52, 28, -0.7, shadowPaint);
    _drawLeaf(canvas, size.width * 0.22, size.height * 0.26, 62, 34, -0.2, shadowPaint);
    _drawLeaf(canvas, size.width * 0.30, size.height * 0.24, 75, 40, -0.5, shadowPaint);
    _drawLeaf(canvas, size.width * 0.38, size.height * 0.32, 70, 36, -0.3, shadowPaint);
    _drawLeaf(canvas, size.width * 0.44, size.height * 0.40, 58, 30, -0.1, shadowPaint);
    _drawLeaf(canvas, size.width * 0.34, size.height * 0.42, 64, 34, 0.2, shadowPaint);
    _drawLeaf(canvas, size.width * 0.24, size.height * 0.36, 56, 30, 0.4, shadowPaint);

    // Far corner soft foliage mass
    _drawLeaf(canvas, 10, size.height * 0.08, 90, 50, -0.8, shadowPaint);
    _drawLeaf(canvas, size.width * 0.08, 10, 85, 45, -0.5, shadowPaint);
    _drawLeaf(canvas, size.width * 0.16, 40, 75, 38, -0.6, shadowPaint);

    // Bottom left soft shadow ground depth
    final ambientGroundPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.8),
        radius: 1.2,
        colors: [
          const Color(0xFFFFFFFF).withOpacity(0.4),
          Colors.transparent,
          const Color(0xFF6B5848).withOpacity(0.03),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), ambientGroundPaint);

    canvas.restore();
  }

  void _drawLeaf(Canvas canvas, double cx, double cy, double length, double width, double angle, Paint paint) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(-length * 0.5, 0);
    path.quadraticBezierTo(0, -width * 0.6, length * 0.5, 0);
    path.quadraticBezierTo(0, width * 0.6, -length * 0.5, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SunlitFoliageShadowPainter oldDelegate) {
    return oldDelegate.sway != sway;
  }
}
