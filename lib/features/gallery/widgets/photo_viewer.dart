// lib/features/gallery/widgets/photo_viewer.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/strings.dart';
import '../../../core/theme/glassmorphism.dart';

/// Full‑screen photo viewer with pinch‑to‑zoom and optional delete/edit
/// actions in the app bar.
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({
    super.key,
    required this.filePath,
    this.onDelete,
    this.onReplace,
  });

  /// Absolute path to the image file.
  final String filePath;

  /// Called when the user confirms deletion of the current photo.
  final VoidCallback? onDelete;

  /// Called when the user chooses to replace the photo with a new pick.
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (onReplace != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _replacePhoto(context),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Center(
        child: exists
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      _errorWidget(context),
                ),
              )
            : _errorWidget(context),
      ),
    );
  }

  Widget _errorWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image, size: 80, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          Strings.galleryPhotoPickerError,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
              // After deletion, pop back from viewer
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(Strings.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _replacePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (!context.mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: const Color(0xFFFF6B81),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0xFF000000),
        ),
        IOSUiSettings(title: 'Crop Photo'),
      ],
    );

    if (cropped == null) return;
    // Overwrite the original file
    final croppedFile = File(cropped.path);
    final destFile = File(filePath);
    await croppedFile.copy(destFile.path);
    onReplace?.call();
    // Popping after replace might not be needed if we want to stay; we'll just pop back.
    if (context.mounted) Navigator.of(context).pop();
  }
}