import 'package:flutter/material.dart';
import '../theme/premium_theme.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color color;
  final Border? border;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 15.0,
    this.opacity = 0.85,
    this.color = PremiumTheme.surfaceCard,
    this.border,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        color: color.withOpacity(opacity),
        borderRadius: shape == BoxShape.circle 
            ? null 
            : BorderRadius.circular(borderRadius),
        border: border ?? Border.all(
          color: PremiumTheme.goldBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E522E).withOpacity(0.06), // Soft warm golden ambient shadow
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
