// lib/core/utils/permission_handler.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/strings.dart';

/// A stateless service that centralises permission requests and checks for
/// the "Our Heart" application.
///
/// Each method returns `true` if the permission is granted, `false` otherwise.
/// If a permission was permanently denied, the user is informed via a dialog
/// with a prompt to open system settings.
class AppPermissionHandler {
  AppPermissionHandler._();

  /// Requests storage permission (Android 12 and below).
  /// On Android 13+ the storage permission is no longer required for
  /// app‑private directories, but we still handle it gracefully.
  static Future<bool> requestStorage(BuildContext context) async {
    return _request(context, Permission.storage, Strings.permissionStorage);
  }

  /// Requests camera permission.
  static Future<bool> requestCamera(BuildContext context) async {
    return _request(context, Permission.camera, Strings.permissionCamera);
  }

  /// Requests notification permission (Android 13+).
  static Future<bool> requestNotifications(BuildContext context) async {
    return _request(context, Permission.notification, Strings.permissionNotifications);
  }

  /// Requests the ability to run a foreground service (Android 9+).
  /// On older devices or unsupported platforms this simply returns true.
  static Future<bool> requestForegroundService(BuildContext context) async {
    // The foreground service permission was introduced in Android 9 (API 28).
    // On earlier versions it is implicitly granted.
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, Strings.permissionBackground);
      return false;
    }
    return false;
  }

  /// Core request helper that shows a rationale dialog if needed and
  /// navigates to settings on permanent denial.
  static Future<bool> _request(
    BuildContext context,
    Permission permission,
    String rationaleMessage,
  ) async {
    final status = await permission.request();

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(context, rationaleMessage);
      return false;
    }

    // Denied but not permanently – the user can be asked again.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rationaleMessage)),
      );
    }
    return false;
  }

  static void _showPermanentlyDeniedDialog(
    BuildContext context,
    String rationale,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Strings.permissionDeniedPermanently),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text(Strings.ok),
          ),
        ],
      ),
    );
  }
}