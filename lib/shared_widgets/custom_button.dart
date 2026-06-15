// lib/shared_widgets/custom_button.dart

import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// A styled button used across the application for primary actions.
///
/// Supports both filled and outlined variants, with a glassmorphic subtlety.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isOutlined
        ? (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary)
        : Colors.white;
    final bgColor = isOutlined
        ? Colors.transparent
        : AppColors.primary;
    final borderSide = isOutlined
        ? BorderSide(
            color: isDark ? AppColors.textDarkSecondary : AppColors.primary,
            width: 1.5,
          )
        : BorderSide.none;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: fgColor,
        backgroundColor: bgColor,
        disabledBackgroundColor: bgColor.withOpacity(0.5),
        disabledForegroundColor: fgColor.withOpacity(0.5),
        side: borderSide,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: isOutlined ? 0 : 4,
        shadowColor: isOutlined ? Colors.transparent : AppColors.primary.withOpacity(0.3),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fgColor,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}