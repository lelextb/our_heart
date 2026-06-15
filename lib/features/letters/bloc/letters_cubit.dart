// lib/features/letters/bloc/letters_cubit.dart

import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/letter_repository.dart';
import 'letters_state.dart';

/// Manages the Letters feature: loading, adding, updating, and deleting letters.
class LettersCubit extends Cubit<LettersState> {
  LettersCubit({required this.repository}) : super(const LettersState());

  final LetterRepository repository;

  /// Loads all letters from the repository, ordered by most recent first.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final letters = await repository.getAll();
      final data = letters
          .map((l) => LetterData(
                id: l.id,
                title: l.title,
                content: l.content,
                createdAt: l.createdAt,
                updatedAt: l.updatedAt,
              ))
          .toList();
      emit(state.copyWith(isLoading: false, letters: data));
    } catch (e, st) {
      dev.log('LettersCubit load error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load letters.',
      ));
    }
  }

  /// Adds a new letter with the given title and content.
  Future<void> add({
    required String title,
    required String content,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.add(title: title, content: content);
      await load();
    } catch (e, st) {
      dev.log('LettersCubit add error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not save letter.',
      ));
    }
  }

  /// Updates an existing letter identified by [id].
  Future<void> update({
    required int id,
    required String title,
    required String content,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.update(id: id, title: title, content: content);
      await load();
    } catch (e, st) {
      dev.log('LettersCubit update error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not update letter.',
      ));
    }
  }

  /// Deletes the letter with the given [id].
  Future<void> delete(int id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.delete(id);
      await load();
    } catch (e, st) {
      dev.log('LettersCubit delete error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not delete letter.',
      ));
    }
  }
}