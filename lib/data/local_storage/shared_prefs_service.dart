import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class SharedPrefsService {
  SharedPrefsService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  // ---- Keys ----
  static const _keyYourName = 'your_name';
  static const _keyPartnerName = 'partner_name';
  static const _keyYourGender = 'your_gender';
  static const _keyPartnerGender = 'partner_gender';
  static const _keyThemeMode = 'theme_mode';
  static const _keyRelationshipStart = 'relationship_start'; // millisecondsSinceEpoch (LOCAL)
  static const _keyYourProfilePath = 'your_profile_path';
  static const _keyPartnerProfilePath = 'partner_profile_path';
  static const _keyYourBirthday = 'your_birthday';
  static const _keyPartnerBirthday = 'partner_birthday';
  static const _keyLoveLanguages = 'love_languages';

  // ---- Getters ----
  String get yourName => _prefs.getString(_keyYourName) ?? '';
  String get partnerName => _prefs.getString(_keyPartnerName) ?? '';
  String get yourGender => _prefs.getString(_keyYourGender) ?? '';
  String get partnerGender => _prefs.getString(_keyPartnerGender) ?? '';
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  String get yourProfilePath => _prefs.getString(_keyYourProfilePath) ?? '';
  String get partnerProfilePath => _prefs.getString(_keyPartnerProfilePath) ?? '';

  DateTime get relationshipStart {
    final ms = _prefs.getInt(_keyRelationshipStart);
    if (ms == null || ms == 0) return AppConstants.defaultRelationshipStart;
    // Use local time to preserve the exact date picked by the user
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
  }

  DateTime? get yourBirthday {
    final ms = _prefs.getInt(_keyYourBirthday);
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
  }

  DateTime? get partnerBirthday {
    final ms = _prefs.getInt(_keyPartnerBirthday);
    if (ms == null || ms == 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false);
  }

  List<String> get loveLanguages {
    final raw = _prefs.getString(_keyLoveLanguages);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  // ---- Setters ----
  Future<void> setYourName(String value) => _setString(_keyYourName, value);
  Future<void> setPartnerName(String value) => _setString(_keyPartnerName, value);
  Future<void> setYourGender(String value) => _setString(_keyYourGender, value);
  Future<void> setPartnerGender(String value) => _setString(_keyPartnerGender, value);
  Future<void> setThemeMode(String value) => _setString(_keyThemeMode, value);

  Future<void> setRelationshipStart(DateTime date) async {
    try {
      // Store as LOCAL milliseconds to avoid time‑zone shifts
      await _prefs.setInt(_keyRelationshipStart, date.millisecondsSinceEpoch);
    } catch (e, st) {
      dev.log('Failed to write relationship start', error: e, stackTrace: st);
    }
  }

  Future<void> setYourProfilePath(String path) => _setString(_keyYourProfilePath, path);
  Future<void> setPartnerProfilePath(String path) => _setString(_keyPartnerProfilePath, path);

  Future<void> setYourBirthday(DateTime? date) async {
    try {
      if (date == null) {
        await _prefs.remove(_keyYourBirthday);
      } else {
        await _prefs.setInt(_keyYourBirthday, date.millisecondsSinceEpoch);
      }
    } catch (e, st) {
      dev.log('Failed to write your birthday', error: e, stackTrace: st);
    }
  }

  Future<void> setPartnerBirthday(DateTime? date) async {
    try {
      if (date == null) {
        await _prefs.remove(_keyPartnerBirthday);
      } else {
        await _prefs.setInt(_keyPartnerBirthday, date.millisecondsSinceEpoch);
      }
    } catch (e, st) {
      dev.log('Failed to write partner birthday', error: e, stackTrace: st);
    }
  }

  Future<void> setLoveLanguages(List<String> languages) async {
    try {
      final encoded = jsonEncode(languages);
      await _prefs.setString(_keyLoveLanguages, encoded);
    } catch (e, st) {
      dev.log('Failed to write love languages', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic> toExportMap() {
    return {
      _keyYourName: yourName,
      _keyPartnerName: partnerName,
      _keyYourGender: yourGender,
      _keyPartnerGender: partnerGender,
      _keyThemeMode: themeMode,
      _keyRelationshipStart: relationshipStart.toIso8601String(),
      _keyYourProfilePath: yourProfilePath,
      _keyPartnerProfilePath: partnerProfilePath,
      _keyYourBirthday: yourBirthday?.toIso8601String(),
      _keyPartnerBirthday: partnerBirthday?.toIso8601String(),
      _keyLoveLanguages: loveLanguages,
    };
  }

  Future<void> _setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e, st) {
      dev.log('Failed to write SharedPrefs key "$key"', error: e, stackTrace: st);
    }
  }
}