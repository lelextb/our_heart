// lib/features/settings/widgets/settings_section.dart

import 'package:flutter/material.dart';

import '../../../shared_widgets/glassmorphic_card.dart';

/// A reusable section for the Settings page. Displays a title and a list
/// of children (typically [ListTile] widgets) inside a GlassmorphicCard.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
  });

  /// Section header text (e.g., "Profile").
  final String title;

  /// Widgets representing the individual settings rows.
  final List<Widget> children;

  /// Optional custom padding for the inner content.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicCard(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}