// lib/features/info/widgets/info_card.dart

import 'package:flutter/material.dart';

import '../../../shared_widgets/glassmorphic_card.dart';
import '../bloc/info_state.dart';

/// A card widget that displays a summary of an Info entry (title and truncated
/// content) inside a GlassmorphicCard.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  final InfoEntryData entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            entry.content,
            style: theme.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}