// lib/features/home/bloc/home_state.dart

import 'package:equatable/equatable.dart';

/// Represents the data displayed on the Home page, including profile
/// information, relationship counter, affirmations, birthdays,
/// love languages, and a dynamic pronounce phrase.
class HomeState extends Equatable {
  final String yourName;
  final String partnerName;
  final String yourProfilePath;
  final String partnerProfilePath;
  final DateTime relationshipStart;

  /// List of daily affirmation strings (max 3).
  final List<String> affirmations;

  /// Your birthday (month‑day only; year is ignored).
  final DateTime? yourBirthday;

  /// Partner's birthday (month‑day only; year is ignored).
  final DateTime? partnerBirthday;

  /// The five love languages in the user's preferred order.
  /// Up to 5 strings; empty list means not set.
  final List<String> loveLanguages;

  /// Dynamic phrase based on partner's age, e.g. "She's 15 soon 16".
  /// `null` when the partner's birthday is not set.
  final String? pronounceText;

  final String? errorMessage;
  final bool isLoading;

  const HomeState({
    this.yourName = '',
    this.partnerName = '',
    this.yourProfilePath = '',
    this.partnerProfilePath = '',
    required this.relationshipStart,
    this.affirmations = const [],
    this.yourBirthday,
    this.partnerBirthday,
    this.loveLanguages = const [],
    this.pronounceText,
    this.errorMessage,
    this.isLoading = false,
  });

  HomeState copyWith({
    String? yourName,
    String? partnerName,
    String? yourProfilePath,
    String? partnerProfilePath,
    DateTime? relationshipStart,
    List<String>? affirmations,
    DateTime? yourBirthday,
    bool clearYourBirthday = false,
    DateTime? partnerBirthday,
    bool clearPartnerBirthday = false,
    List<String>? loveLanguages,
    String? pronounceText,
    bool clearPronounceText = false,
    String? errorMessage,
    bool? isLoading,
  }) {
    return HomeState(
      yourName: yourName ?? this.yourName,
      partnerName: partnerName ?? this.partnerName,
      yourProfilePath: yourProfilePath ?? this.yourProfilePath,
      partnerProfilePath: partnerProfilePath ?? this.partnerProfilePath,
      relationshipStart: relationshipStart ?? this.relationshipStart,
      affirmations: affirmations ?? this.affirmations,
      yourBirthday:
          clearYourBirthday ? null : yourBirthday ?? this.yourBirthday,
      partnerBirthday:
          clearPartnerBirthday ? null : partnerBirthday ?? this.partnerBirthday,
      loveLanguages: loveLanguages ?? this.loveLanguages,
      pronounceText:
          clearPronounceText ? null : pronounceText ?? this.pronounceText,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        yourName,
        partnerName,
        yourProfilePath,
        partnerProfilePath,
        relationshipStart,
        affirmations,
        yourBirthday,
        partnerBirthday,
        loveLanguages,
        pronounceText,
        errorMessage,
        isLoading,
      ];
}