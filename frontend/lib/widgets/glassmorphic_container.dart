import 'package:flutter/material.dart';
import '../theme/premium_theme.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final BoxShape shape;
  final Gradient? gradient;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.blur = 16,
    this.opacity = 0.95,
    this.padding,
    this.margin,
    this.border,
    this.shape = BoxShape.rectangle,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        color: shape == BoxShape.circle ? Colors.white : PremiumTheme.surfaceCard,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: PremiumTheme.goldBorder.withOpacity(0.8), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A3728).withOpacity(0.06), // Soft warm organic shadow
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
