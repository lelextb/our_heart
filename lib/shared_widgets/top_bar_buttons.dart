import 'package:flutter/material.dart';

/// Row of icon buttons displayed at the top of the main content area,
/// providing quick access to Settings, Reminders, Letters, and Gallery.
///
/// Positioned absolutely by the parent screen.
class TopBarButtons extends StatelessWidget {
  const TopBarButtons({
    super.key,
    this.onSettingsTap,
    this.onRemindersTap,
    this.onLettersTap,
    this.onGalleryTap,
  });

  final VoidCallback? onSettingsTap;
  final VoidCallback? onRemindersTap;
  final VoidCallback? onLettersTap;
  final VoidCallback? onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side buttons
        Row(
          children: [
            _TopBarIconButton(
              icon: Icons.settings_outlined,
              onTap: onSettingsTap,
            ),
            const SizedBox(width: 8),
            _TopBarIconButton(
              icon: Icons.notifications_outlined,
              onTap: onRemindersTap,
            ),
            const SizedBox(width: 8),
            _TopBarIconButton(
              icon: Icons.photo_library_outlined,
              onTap: onGalleryTap,
            ),
          ],
        ),
        // Right side button
        _TopBarIconButton(
          icon: Icons.email_outlined,
          onTap: onLettersTap,
        ),
      ],
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onTap,
      splashRadius: 20,
      tooltip: null,
    );
  }
}