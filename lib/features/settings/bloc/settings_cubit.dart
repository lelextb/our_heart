// lib/features/settings/bloc/settings_cubit.dart

import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/export_utils.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/constants/strings.dart';
import '../../../data/database/database.dart';
import '../../../data/local_storage/shared_prefs_service.dart';
import '../../../data/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required this.settingsRepo,
    required this.database,
    required this.prefs,
  }) : super(SettingsState(
          relationshipStart: settingsRepo.relationshipStart,
        ));

  final SettingsRepository settingsRepo;
  final AppDatabase database;
  final SharedPrefsService prefs;

  /// Loads current settings from the repository and populates the state.
  Future<void> load() async {
    try {
      emit(state.copyWith(isSaving: false, errorMessage: null));
      final repo = settingsRepo;
      emit(state.copyWith(
        yourName: repo.yourName,
        partnerName: repo.partnerName,
        yourGender: repo.yourGender,
        partnerGender: repo.partnerGender,
        themeMode: repo.themeMode,
        yourProfilePath: repo.yourProfilePath,
        partnerProfilePath: repo.partnerProfilePath,
        relationshipStart: repo.relationshipStart,
        yourBirthday: repo.yourBirthday,
        partnerBirthday: repo.partnerBirthday,
        loveLanguages: repo.loveLanguages,
      ));
    } catch (e, st) {
      dev.log('SettingsCubit load error', error: e, stackTrace: st);
      emit(state.copyWith(errorMessage: 'Could not load settings.'));
    }
  }

  // ---------- Simple text fields ----------
  Future<void> updateYourName(String name) async {
    await _save(() => settingsRepo.updateYourName(name.trim()));
    emit(state.copyWith(yourName: name.trim(), errorMessage: null));
  }

  Future<void> updatePartnerName(String name) async {
    await _save(() => settingsRepo.updatePartnerName(name.trim()));
    emit(state.copyWith(partnerName: name.trim(), errorMessage: null));
  }

  Future<void> updateYourGender(String gender) async {
    await _save(() => settingsRepo.updateYourGender(gender));
    emit(state.copyWith(yourGender: gender, errorMessage: null));
  }

  Future<void> updatePartnerGender(String gender) async {
    await _save(() => settingsRepo.updatePartnerGender(gender));
    emit(state.copyWith(partnerGender: gender, errorMessage: null));
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await settingsRepo.updateThemeMode(mode);
    emit(state.copyWith(themeMode: mode, errorMessage: null));
  }

  Future<void> updateRelationshipStart(DateTime date) async {
    await _save(() => settingsRepo.updateRelationshipStart(date));
    emit(state.copyWith(relationshipStart: date, errorMessage: null));
  }

  // ---------- Birthdays ----------
  Future<void> updateYourBirthday(DateTime? date) async {
    await _save(() => settingsRepo.updateYourBirthday(date));
    emit(state.copyWith(yourBirthday: date, errorMessage: null));
  }

  Future<void> updatePartnerBirthday(DateTime? date) async {
    await _save(() => settingsRepo.updatePartnerBirthday(date));
    emit(state.copyWith(partnerBirthday: date, errorMessage: null));
  }

  // ---------- Love languages ----------
  Future<void> updateLoveLanguages(List<String> languages) async {
    await _save(() => settingsRepo.updateLoveLanguages(languages));
    emit(state.copyWith(loveLanguages: languages, errorMessage: null));
  }

  /// Updates the profile picture for the given [type] ('your' or 'partner').
  /// If [customPath] is provided, that path is used directly (e.g., after
  /// picking on the Home page). Otherwise the picker is opened.
  Future<void> updateProfilePicture(String type, {String? customPath}) async {
    try {
      if (customPath != null) {
        // Persist the path to SharedPreferences so HomeCubit picks it up.
        if (type == 'your') {
          await prefs.setYourProfilePath(customPath);
          emit(state.copyWith(yourProfilePath: customPath, errorMessage: null));
        } else {
          await prefs.setPartnerProfilePath(customPath);
          emit(state.copyWith(partnerProfilePath: customPath, errorMessage: null));
        }
        return;
      }

      // Open the picker from within Settings
      final path = await ImageUtils.pickAndCropImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        cropStyle: CropStyle.circle,
        prefix: 'profile_$type',
      );

      if (path == null) return;

      if (type == 'your') {
        await prefs.setYourProfilePath(path);
        emit(state.copyWith(yourProfilePath: path, errorMessage: null));
      } else {
        await prefs.setPartnerProfilePath(path);
        emit(state.copyWith(partnerProfilePath: path, errorMessage: null));
      }
    } catch (e, st) {
      dev.log('Failed to update profile picture', error: e, stackTrace: st);
      emit(state.copyWith(errorMessage: 'Could not update picture.'));
    }
  }

  /// Exports all data to a ZIP file.
  Future<void> exportData() async {
    emit(state.copyWith(isExporting: true, exportMessage: null));
    try {
      final exporter = DataExporter(database: database, prefs: prefs);
      final zipPath = await exporter.exportAll();
      emit(state.copyWith(
        isExporting: false,
        exportMessage: '${Strings.settingsExportSuccess}\n$zipPath',
      ));
    } catch (e, st) {
      dev.log('Export failed', error: e, stackTrace: st);
      emit(state.copyWith(
        isExporting: false,
        exportMessage: Strings.settingsExportFailed,
        errorMessage: 'Export failed.',
      ));
    }
  }

  // ---- Internal helpers ----
  Future<void> _save(Future<void> Function() action) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      await action();
    } catch (e, st) {
      dev.log('Settings save error', error: e, stackTrace: st);
      emit(state.copyWith(errorMessage: 'Failed to save setting.'));
    } finally {
      emit(state.copyWith(isSaving: false));
    }
  }
}