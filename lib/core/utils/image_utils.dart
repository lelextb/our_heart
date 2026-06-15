// lib/core/utils/image_utils.dart

import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  ImageUtils._();

  static Future<String?> pickAndCropImage({
    required ImageSource source,
    int maxWidth = 512,
    int maxHeight = 512,
    CropStyle cropStyle = CropStyle.circle,
    String prefix = 'img',
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (pickedFile == null) return null;

      // Updated cropImage call with cropStyle moved into AndroidUiSettings and IOSUiSettings
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFFFF6B81),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0xFF000000),
            cropGridColor: const Color(0xFFFFFFFF),
            activeControlsWidgetColor: const Color(0xFFFF6B81),
            lockAspectRatio: true,
            cropStyle: cropStyle, // Moved into AndroidUiSettings
          ),
          IOSUiSettings(
            title: 'Crop Image',
            cropStyle: cropStyle, // Moved into IOSUiSettings
          ),
        ],
      );

      if (croppedFile == null) return null;
      return await _saveToPrivateStorage(File(croppedFile.path), prefix: prefix);
    } catch (e, st) {
      dev.log('Image pick/crop error', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<String> _saveToPrivateStorage(
    File file, {
    String prefix = 'img',
  }) async {
    final dir = await imageDirectory;
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.png';
    final dest = File(p.join(dir.path, fileName));
    await file.copy(dest.path);
    return dest.path;
  }

  static Future<String?> generateThumbnail(String originalPath) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final resized = await _resize(bytes, 256, 256);
      if (resized == null) return null;

      final dir = p.dirname(originalPath);
      final baseName = p.basenameWithoutExtension(originalPath);
      final thumbPath = p.join(dir, '${baseName}_thumb.png');
      await File(thumbPath).writeAsBytes(resized);
      return thumbPath;
    } catch (e, st) {
      dev.log('Thumbnail generation error', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<Uint8List?> _resize(
    Uint8List bytes,
    int targetWidth,
    int targetHeight,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      dev.log('Image resize error', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<void> deleteImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      final dir = p.dirname(filePath);
      final baseName = p.basenameWithoutExtension(filePath);
      final thumbPath = p.join(dir, '${baseName}_thumb.png');
      final thumbFile = File(thumbPath);
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    } catch (e, st) {
      dev.log('Image deletion error', error: e, stackTrace: st);
    }
  }

  static Future<Directory> get imageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
}