// lib/core/constants/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  /// Application name displayed in the persistent notification and settings.
  static const String appName = 'Our Heart';

  /// Default relationship start date – Unix epoch as a sentinel meaning "not set".
  /// The actual date is stored in SharedPreferences.
  static final DateTime defaultRelationshipStart = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Maximum number of recent affirmations shown on the Home page.
  static const int maxHomeAffirmations = 3;

  /// Thumbnail size for gallery grid items (logical pixels).
  static const double galleryThumbnailSize = 120.0;

  /// Profile picture diameter.
  static const double profilePictureSize = 96.0;

  /// PIN length required by the auth screen.
  static const int pinLength = 4;

  /// Timeout (in seconds) before the auth screen re‑appears after the app is backgrounded.
  static const int authTimeoutSeconds = 30;

  /// Directory name inside app‑private storage for exported data.
  static const String exportDirName = 'our_heart_exports';

  /// File name for the ZIP archive containing all exported data.
  static const String exportZipName = 'our_heart_backup.zip';
}