// lib/features/gallery/widgets/photo_grid.dart

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../shared_widgets/glassmorphic_card.dart';

class PhotoGridItem {
  final int id;
  final String filePath;
  final String? thumbnailPath;

  const PhotoGridItem({
    required this.id,
    required this.filePath,
    this.thumbnailPath,
  });
}

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.selectedIds,
    required this.onPhotoTap,
    required this.onPhotoLongPress,
    required this.onDeleteSelected,
  });

  final List<PhotoGridItem> photos;
  final Set<int> selectedIds;
  final ValueChanged<int> onPhotoTap;
  final ValueChanged<int> onPhotoLongPress;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = selectedIds.isNotEmpty;

    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,          // larger thumbnails
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,      // square cells
          ),
          itemCount: photos.length,
          itemBuilder: (ctx, index) {
            final photo = photos[index];
            final isSelected = selectedIds.contains(photo.id);
            return GestureDetector(
              onTap: () => onPhotoTap(photo.id),
              onLongPress: () => onPhotoLongPress(photo.id),
              child: GlassmorphicCard(
                padding: EdgeInsets.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildThumbnail(photo),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.check_circle,
                                color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (isSelectionMode)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: onDeleteSelected,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.delete),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail(PhotoGridItem photo) {
    final path = photo.thumbnailPath ?? photo.filePath;
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _brokenImageIcon(),
      );
    }
    return _brokenImageIcon();
  }

  Widget _brokenImageIcon() {
    return const Center(
      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );
  }
}