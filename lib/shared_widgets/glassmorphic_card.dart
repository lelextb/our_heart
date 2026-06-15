import 'package:flutter/material.dart';
import '../core/theme/glassmorphism.dart';

class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16.0);
    Widget card = GlassmorphicContainer(
      padding: padding ?? const EdgeInsets.all(12.0),
      borderRadius: effectiveRadius,
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : null,
        child: card,
      );
    }
    return card;
  }
}