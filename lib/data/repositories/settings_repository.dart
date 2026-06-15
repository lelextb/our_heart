// lib/data/repositories/settings_repository.dart

import 'dart:developer' as dev;

import 'package:flutter/material.dart';

import '../local_storage/shared_prefs_service.dart';

/// Repository that exposes user‑configurable settings to the rest of the app.
///
/// Acts as a thin abstraction over [SharedPrefsService], allowing the
/// settings Cubit/BLoC to remain independent of the underlying storage.
class SettingsRepository {
  const SettingsRepository({required this.prefs});

  final SharedPrefsService prefs;

  // ---- User profiles ----
  String get yourName => prefs.yourName;
  String get partnerName => prefs.partnerName;
  String get yourGender => prefs.yourGender;
  String get partnerGender => prefs.partnerGender;

  // ---- Profile pictures ----
  String get yourProfilePath => prefs.yourProfilePath;
  String get partnerProfilePath => prefs.partnerProfilePath;

  // ---- Birthdays (month‑day only; year is irrelevant) ----
  DateTime? get yourBirthday => prefs.yourBirthday;
  DateTime? get partnerBirthday => prefs.partnerBirthday;

  // ---- Love languages (ordered list) ----
  List<String> get loveLanguages => prefs.loveLanguages;

  // ---- Theme ----
  ThemeMode get themeMode {
    switch (prefs.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ---- Relationship ----
  DateTime get relationshipStart => prefs.relationshipStart;

  // ---- Mutations ----
  Future<void> updateYourName(String name) async {
    try {
      await prefs.setYourName(name);
    } catch (e, st) {
      dev.log('Failed to update your name', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updatePartnerName(String name) async {
    try {
      await prefs.setPartnerName(name);
    } catch (e, st) {
      dev.log('Failed to update partner name', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateYourGender(String gender) async {
    try {
      await prefs.setYourGender(gender);
    } catch (e, st) {
      dev.log('Failed to update your gender', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updatePartnerGender(String gender) async {
    try {
      await prefs.setPartnerGender(gender);
    } catch (e, st) {
      dev.log('Failed to update partner gender', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    try {
      String value;
      switch (mode) {
        case ThemeMode.light:
          value = 'light';
          break;
        case ThemeMode.dark:
          value = 'dark';
          break;
        default:
          value = 'system';
          break;
      }
      await prefs.setThemeMode(value);
    } catch (e, st) {
      dev.log('Failed to update theme mode', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateRelationshipStart(DateTime date) async {
    try {
      await prefs.setRelationshipStart(date);
    } catch (e, st) {
      dev.log('Failed to update relationship start', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateYourProfilePath(String path) async {
    try {
      await prefs.setYourProfilePath(path);
    } catch (e, st) {
      dev.log('Failed to update your profile path', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updatePartnerProfilePath(String path) async {
    try {
      await prefs.setPartnerProfilePath(path);
    } catch (e, st) {
      dev.log('Failed to update partner profile path', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateYourBirthday(DateTime? date) async {
    try {
      await prefs.setYourBirthday(date);
    } catch (e, st) {
      dev.log('Failed to update your birthday', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updatePartnerBirthday(DateTime? date) async {
    try {
      await prefs.setPartnerBirthday(date);
    } catch (e, st) {
      dev.log('Failed to update partner birthday', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateLoveLanguages(List<String> languages) async {
    try {
      await prefs.setLoveLanguages(languages);
    } catch (e, st) {
      dev.log('Failed to update love languages', error: e, stackTrace: st);
      rethrow;
    }
  }
}