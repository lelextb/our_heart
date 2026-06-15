// lib/core/utils/export_utils.dart

import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/database/database.dart';
import '../../data/local_storage/shared_prefs_service.dart';

/// Collects all user data from the Drift database, SharedPreferences, and
/// private image files, then creates a ZIP archive saved to the public
/// Downloads directory (or app‑private as fallback).
class DataExporter {
  const DataExporter({
    required this.database,
    required this.prefs,
  });

  final AppDatabase database;
  final SharedPrefsService prefs;

  /// Executes the export process.
  /// Returns the absolute path of the created ZIP file.
  Future<String> exportAll() async {
    final exportDir = await _prepareExportDirectory();
    final jsonPath = p.join(exportDir.path, 'our_heart_data.json');
    final imagesDir = Directory(p.join(exportDir.path, 'images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // 1. Collect structured data using generated table selectors
    final info = await database.select(database.infoEntries).get();
    final events = await database.select(database.events).get();
    final reminders = await database.select(database.reminders).get();
    final letters = await database.select(database.letters).get();
    final photos = await database.select(database.photos).get();

    final dataMap = {
      'settings': prefs.toExportMap(),
      'infoEntries': info.map((e) => e.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'letters': letters.map((l) => l.toJson()).toList(),
      'photos': photos.map((p) => p.toJson()).toList(),
    };

    await File(jsonPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(dataMap),
      flush: true,
    );

    // 2. Copy image files
    for (final photo in photos) {
      final src = File(photo.filePath);
      if (await src.exists()) {
        final destName = p.basename(photo.filePath);
        await src.copy(p.join(imagesDir.path, destName));
      }
      if (photo.thumbnailPath != null) {
        final thumbSrc = File(photo.thumbnailPath!);
        if (await thumbSrc.exists()) {
          final thumbName = p.basename(photo.thumbnailPath!);
          await thumbSrc.copy(p.join(imagesDir.path, thumbName));
        }
      }
    }

    // Also copy profile pictures if they exist
    final yourProfilePath = await _getProfilePath('profile_your');
    final partnerProfilePath = await _getProfilePath('profile_partner');
    if (yourProfilePath != null) {
      final src = File(yourProfilePath);
      if (await src.exists()) {
        await src.copy(p.join(imagesDir.path, 'your_profile.png'));
      }
    }
    if (partnerProfilePath != null) {
      final src = File(partnerProfilePath);
      if (await src.exists()) {
        await src.copy(p.join(imagesDir.path, 'partner_profile.png'));
      }
    }

    // 3. Create ZIP archive
    final zipPath = await _createZip(exportDir);
    return zipPath;
  }

  Future<Directory> _prepareExportDirectory() async {
    final downloadsDir = await _publicDownloadsDirectory();
    final exportDir =
        Directory(p.join(downloadsDir.path, AppConstants.exportDirName));
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create(recursive: true);
    return exportDir;
  }

  /// Attempts to use the public Downloads directory; falls back to
  /// app‑private documents if unavailable (e.g., scoped storage restrictions).
  Future<Directory> _publicDownloadsDirectory() async {
    try {
      // On many Android devices /storage/emulated/0/Download is accessible.
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
    } catch (_) {
      // Fallback: any exception leaves dir unchanged.
    }
    // Safe fallback inside app sandbox
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDir.path, 'exports'));
  }

  Future<String> _createZip(Directory sourceDir) async {
    final encoder = ZipEncoder();
    final archive = Archive();

    final files = await sourceDir.list(recursive: true).toList();
    for (final entity in files) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourceDir.path);
        final bytes = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(archiveFile);
      }
    }

    final zipData = encoder.encode(archive);
    if (zipData == null) throw Exception('ZIP encoding failed');

    final outPath =
        p.join(sourceDir.parent.path, AppConstants.exportZipName);
    final outFile = File(outPath);
    await outFile.writeAsBytes(zipData, flush: true);

    // Clean up temporary export directory
    await sourceDir.delete(recursive: true);

    return outPath;
  }

  Future<String?> _getProfilePath(String prefix) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'images'));
    if (!await dir.exists()) return null;
    final files = await dir.list().toList();
    for (final f in files) {
      if (f is File) {
        final name = p.basename(f.path);
        if (name.startsWith(prefix)) {
          return f.path;
        }
      }
    }
    return null;
  }
}