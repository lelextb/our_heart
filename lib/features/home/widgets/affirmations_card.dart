// lib/features/home/widgets/affirmations_card.dart

import 'package:flutter/material.dart';
import '../../../shared_widgets/glassmorphic_card.dart';

/// Displays a list of daily affirmations inside a GlassmorphicCard.
class AffirmationsCard extends StatelessWidget {
  const AffirmationsCard({
    super.key,
    required this.affirmations,
  });

  final List<String> affirmations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today’s Affirmations',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (affirmations.isEmpty)
            Text(
              'No affirmations yet. Stay positive!',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...affirmations.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}