// lib/core/theme/glassmorphism.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:our_heart/core/theme/colors.dart';

/// A reusable Glassmorphism container widget that applies a backdrop‑filter
/// blur with a semi‑transparent background and rounded border.
///
/// The blur intensity, background colour, border radius, and padding are
/// configurable.  Defaults use the app’s colour palette.
class GlassmorphicContainer extends StatelessWidget {
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blurSigmaX = 10.0,
    this.blurSigmaY = 10.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(20.0)),
    this.borderColor,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16.0),
  });

  /// Widget displayed inside the glass container.
  final Widget child;

  /// Optional fixed dimensions.  If null, the container sizes itself to its child.
  final double? width;
  final double? height;

  /// Sigma values for the Gaussian blur (X and Y directions).
  final double blurSigmaX;
  final double blurSigmaY;

  /// Corner radius of the container.
  final BorderRadiusGeometry borderRadius;

  /// Optional border colour (overrides the default theme‑aware colour).
  final Color? borderColor;

  /// Optional background colour (overrides the default theme‑aware colour).
  final Color? backgroundColor;

  /// Inner padding around the child.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.glassDark : AppColors.glassLight);
    final border = borderColor ??
        (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border: Border.all(color: border, width: 1.5),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}