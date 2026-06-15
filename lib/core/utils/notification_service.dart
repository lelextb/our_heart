import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';

class NotificationService {
  NotificationService._();

  static const _channel = MethodChannel('com.example.our_heart/counter');

  /// Starts the persistent counter notification with the given [startDate].
  /// Retries once after a short delay if the permission was not yet granted.
  static Future<bool> startService(DateTime startDate) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'startService',
        {'startDate': startDate.millisecondsSinceEpoch},
      );
      if (result == true) return true;

      // Permission not granted yet – wait for the system dialog and retry
      await Future.delayed(const Duration(seconds: 2));
      final retry = await _channel.invokeMethod<bool>(
        'startService',
        {'startDate': startDate.millisecondsSinceEpoch},
      );
      return retry ?? false;
    } on PlatformException catch (e) {
      dev.log('Failed to start counter service: ${e.code} - ${e.message}');
      return false;
    } catch (e, st) {
      dev.log('Failed to start counter service', error: e, stackTrace: st);
      return false;
    }
  }

  /// Stops the persistent notification and the foreground service.
  static Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } catch (e, st) {
      dev.log('Failed to stop counter service', error: e, stackTrace: st);
      return false;
    }
  }

  /// Updates the relationship start date while the service is running.
  static Future<bool> updateDate(DateTime newDate) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'updateDate',
        {'startDate': newDate.millisecondsSinceEpoch},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      dev.log('Failed to update counter date: ${e.code} - ${e.message}');
      return false;
    } catch (e, st) {
      dev.log('Failed to update counter date', error: e, stackTrace: st);
      return false;
    }
  }
}