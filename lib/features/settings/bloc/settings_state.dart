// lib/features/settings/bloc/settings_state.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final String yourName;
  final String partnerName;
  final String yourGender;
  final String partnerGender;
  final ThemeMode themeMode;
  final String yourProfilePath;
  final String partnerProfilePath;
  final DateTime relationshipStart;

  /// Your birthday (month‑day only; year is irrelevant).  `null` = not set.
  final DateTime? yourBirthday;

  /// Partner's birthday (month‑day only; year is irrelevant).  `null` = not set.
  final DateTime? partnerBirthday;

  /// Ordered list of love languages (max 5).  Empty = not set.
  final List<String> loveLanguages;

  final bool isExporting;
  final String? exportMessage;
  final bool isSaving;
  final String? errorMessage;

  const SettingsState({
    this.yourName = '',
    this.partnerName = '',
    this.yourGender = '',
    this.partnerGender = '',
    this.themeMode = ThemeMode.system,
    this.yourProfilePath = '',
    this.partnerProfilePath = '',
    required this.relationshipStart,
    this.yourBirthday,
    this.partnerBirthday,
    this.loveLanguages = const [],
    this.isExporting = false,
    this.exportMessage,
    this.isSaving = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    String? yourName,
    String? partnerName,
    String? yourGender,
    String? partnerGender,
    ThemeMode? themeMode,
    String? yourProfilePath,
    String? partnerProfilePath,
    DateTime? relationshipStart,
    DateTime? yourBirthday,
    bool clearYourBirthday = false,
    DateTime? partnerBirthday,
    bool clearPartnerBirthday = false,
    List<String>? loveLanguages,
    bool? isExporting,
    String? exportMessage,
    bool? isSaving,
    String? errorMessage,
  }) {
    return SettingsState(
      yourName: yourName ?? this.yourName,
      partnerName: partnerName ?? this.partnerName,
      yourGender: yourGender ?? this.yourGender,
      partnerGender: partnerGender ?? this.partnerGender,
      themeMode: themeMode ?? this.themeMode,
      yourProfilePath: yourProfilePath ?? this.yourProfilePath,
      partnerProfilePath: partnerProfilePath ?? this.partnerProfilePath,
      relationshipStart: relationshipStart ?? this.relationshipStart,
      yourBirthday:
          clearYourBirthday ? null : yourBirthday ?? this.yourBirthday,
      partnerBirthday:
          clearPartnerBirthday ? null : partnerBirthday ?? this.partnerBirthday,
      loveLanguages: loveLanguages ?? this.loveLanguages,
      isExporting: isExporting ?? this.isExporting,
      exportMessage: exportMessage,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        yourName,
        partnerName,
        yourGender,
        partnerGender,
        themeMode,
        yourProfilePath,
        partnerProfilePath,
        relationshipStart,
        yourBirthday,
        partnerBirthday,
        loveLanguages,
        isExporting,
        exportMessage,
        isSaving,
        errorMessage,
      ];
}