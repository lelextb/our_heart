// lib/data/local_storage/secure_storage_service.dart

import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [FlutterSecureStorage] that provides a typed API for the
/// security‑sensitive key‑value pairs used in "Our Heart" (PIN hash, salt).
///
/// On Android the underlying implementation uses Android Keystore; on debug
/// builds plain SharedPreferences may be used (as configured by the plugin).
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // ---- Keys ----
  static const _keyPinHash = 'pin_hash';
  static const _keyPinSalt = 'pin_salt';

  /// Stores the hashed PIN and its salt.
  Future<void> savePinCredentials({
    required String hash,
    required String salt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyPinHash, value: hash),
        _storage.write(key: _keyPinSalt, value: salt),
      ]);
    } catch (e, st) {
      dev.log('Failed to save PIN credentials', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Reads the stored PIN hash. Returns `null` if not set.
  Future<String?> get pinHash async {
    try {
      return await _storage.read(key: _keyPinHash);
    } catch (e, st) {
      dev.log('Failed to read PIN hash', error: e, stackTrace: st);
      return null;
    }
  }

  /// Reads the stored PIN salt. Returns `null` if not set.
  Future<String?> get pinSalt async {
    try {
      return await _storage.read(key: _keyPinSalt);
    } catch (e, st) {
      dev.log('Failed to read PIN salt', error: e, stackTrace: st);
      return null;
    }
  }

  /// Deletes all stored credentials (used when clearing the PIN).
  Future<void> clearCredentials() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyPinHash),
        _storage.delete(key: _keyPinSalt),
      ]);
    } catch (e, st) {
      dev.log('Failed to clear credentials', error: e, stackTrace: st);
    }
  }
}