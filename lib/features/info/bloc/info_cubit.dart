// lib/features/info/bloc/info_cubit.dart

import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/info_repository.dart';
import 'info_state.dart';

/// Manages the list of Info entries: loading, adding, updating, deleting.
class InfoCubit extends Cubit<InfoState> {
  InfoCubit({required this.repository}) : super(const InfoState());

  final InfoRepository repository;

  /// Loads all info entries from the repository and emits them.
  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final entries = await repository.getAll();
      final data = entries
          .map((e) => InfoEntryData(
                id: e.id,
                title: e.title,
                content: e.content,
                createdAt: e.createdAt,
              ))
          .toList();
      emit(state.copyWith(isLoading: false, entries: data));
    } catch (e, st) {
      dev.log('InfoCubit load error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load info entries.',
      ));
    }
  }

  /// Adds a new info entry with the given [title] and [content].
  Future<void> add({
    required String title,
    required String content,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.add(title: title, content: content);
      await load(); // reload the full list
    } catch (e, st) {
      dev.log('InfoCubit add error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not save entry.',
      ));
    }
  }

  /// Updates an existing entry identified by [id].
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
      dev.log('InfoCubit update error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not update entry.',
      ));
    }
  }

  /// Deletes the entry with the given [id].
  Future<void> delete(int id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.delete(id);
      await load();
    } catch (e, st) {
      dev.log('InfoCubit delete error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not delete entry.',
      ));
    }
  }
}