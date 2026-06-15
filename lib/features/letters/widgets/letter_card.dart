// lib/features/letters/widgets/letter_card.dart

import 'package:flutter/material.dart';
import '../../../shared_widgets/glassmorphic_card.dart';

/// A card that summarises a letter (title + truncated content) with a
/// stamp‑style date label.
class LetterCard extends StatelessWidget {
  const LetterCard({
    super.key,
    required this.title,
    required this.content,
    required this.createdAt,
    this.onTap,
  });

  final String title;
  final String content;
  final DateTime createdAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return GlassmorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                Icons.mail_outline,
                size: 28,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}