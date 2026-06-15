import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../shared_widgets/glassmorphic_card.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.description,
    required this.reminderTime,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  final String description;
  final DateTime reminderTime;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime =
        '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Stack(
          children: [
            GlassmorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: theme.textTheme.bodyLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedTime,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: theme.colorScheme.error),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}