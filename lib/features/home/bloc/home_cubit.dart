import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/notification_service.dart';
import '../../../data/repositories/settings_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this.settingsRepo})
      : super(HomeState(
          relationshipStart: settingsRepo.relationshipStart,
        ));

  final SettingsRepository settingsRepo;

  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      _loadAll();
      emit(state.copyWith(isLoading: false));
    } catch (e, st) {
      dev.log('HomeCubit init error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Failed to load home data.'));
    }
  }

  void refreshRelationship() {
    try {
      _loadAll();
    } catch (e, st) {
      dev.log('refreshRelationship error', error: e, stackTrace: st);
    }
  }

  void _loadAll() {
    final repo = settingsRepo;

    final pronounce = _buildPronounce(
      repo.partnerBirthday,
      repo.partnerName,
    );

    final affirmations = _pickDailyAffirmations(3);

    emit(state.copyWith(
      yourName: repo.yourName,
      partnerName: repo.partnerName,
      yourProfilePath: repo.yourProfilePath,
      partnerProfilePath: repo.partnerProfilePath,
      relationshipStart: repo.relationshipStart,
      yourBirthday: repo.yourBirthday,
      partnerBirthday: repo.partnerBirthday,
      loveLanguages: repo.loveLanguages,
      pronounceText: pronounce,
      affirmations: affirmations,
    ));

    // Start / update the persistent counter notification
    _updateForegroundService(repo.relationshipStart);
  }

  void _updateForegroundService(DateTime start) {
    if (start == AppConstants.defaultRelationshipStart) return;

    NotificationService.startService(start);
  }

  String? _buildPronounce(DateTime? birthday, String partnerName) {
    if (birthday == null) return null;

    final now = DateTime.now();
    int age = now.year - birthday.year;

    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }

    if (age < 0) age = 0;

    final pronoun = partnerName.isNotEmpty ? partnerName : 'Partner';

    if (now.month == birthday.month && now.day == birthday.day) {
      return '$pronoun is $age today! 🎂';
    }

    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      return '$pronoun is $age soon ${age + 1}';
    }

    return '$pronoun is $age';
  }

  List<String> _pickDailyAffirmations(int count) {
    const pool = [
      'You are enough, exactly as you are.',
      'Love grows deeper every day.',
      'Together is a wonderful place to be.',
      'Your heart knows the way.',
      'Every moment shared is a treasure.',
      'You make each other better.',
      'Kindness is your superpower.',
      'Today is full of possibilities.',
      'Gratitude turns what you have into enough.',
      'Your love story is beautiful.',
      'Cherish the little things.',
      'You are stronger together.',
      'Happiness blooms from within.',
      'You deserve all the love in the world.',
      'The best is yet to come.',
    ];

    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final shuffled = List<String>.from(pool)..shuffle(random);
    return shuffled.take(count).toList();
  }
}