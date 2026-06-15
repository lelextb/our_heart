import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/utils/local_notification_service.dart';
import 'data/database/database.dart';
import 'data/local_storage/secure_storage_service.dart';
import 'data/local_storage/shared_prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.initialize();

  final secureStorage = SecureStorageService();
  final prefs = await SharedPreferences.getInstance();
  final sharedPrefsService = SharedPrefsService(prefs: prefs);
  final database = AppDatabase();

  runApp(
    OurHeartApp(
      database: database,
      secureStorage: secureStorage,
      sharedPrefs: sharedPrefsService,
    ),
  );
}