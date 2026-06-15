// lib/features/gallery/widgets/category_card.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';

/// A glassmorphic card representing a photo category (album) with a subtle
/// shadow, the category name, a brief description, a thumbnail (first photo),
/// and the number of photos it contains. Tapping opens the category, the
/// camera button adds a photo directly.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.name,
    required this.description,
    required this.thumbnailPath,
    required this.photoCount,
    this.onTap,
    this.onAddPhoto,
  });

  final String name;
  final String? description;
  final String? thumbnailPath;
  final int photoCount;
  final VoidCallback? onTap;
  final VoidCallback? onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GlassmorphicContainer(
          backgroundColor: glassBg,
          borderColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: thumbnailPath != null &&
                          File(thumbnailPath!).existsSync()
                      ? Image.file(File(thumbnailPath!), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primary.withOpacity(0.15),
                          child: const Icon(Icons.photo_library_outlined,
                              size: 32, color: Colors.white54),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '$photoCount photo${photoCount == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Add photo button
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined, size: 22),
                color: AppColors.primary,
                onPressed: onAddPhoto,
              ),
            ],
          ),
        ),
      ),
    );
  }
}