import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/local_notification_service.dart';
import '../../../data/repositories/reminder_repository.dart';
import 'reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit({required this.repository}) : super(const RemindersState());

  final ReminderRepository repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final reminders = await repository.getAll();
      final data = reminders
          .map((r) => ReminderData(
                id: r.id,
                description: r.description,
                reminderTime: r.reminderTime,
                isTriggered: r.isTriggered,
              ))
          .toList();
      emit(state.copyWith(isLoading: false, reminders: data));
    } catch (e, st) {
      dev.log('RemindersCubit load error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not load reminders.'));
    }
  }

  Future<void> add({
    required String description,
    required DateTime reminderTime,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final newId = await repository.add(
          description: description, reminderTime: reminderTime);
      dev.log('Reminder added with id: $newId');
      await load();
      // Schedule notification
      dev.log('Calling scheduleReminder with id=$newId, description=$description, time=$reminderTime');
      await LocalNotificationService.scheduleReminder(
        id: newId,
        description: description,
        reminderTime: reminderTime,
      );
    } catch (e, st) {
      dev.log('RemindersCubit add error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not save reminder.'));
    }
  }

  Future<void> update({
    required int id,
    String? description,
    DateTime? reminderTime,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.update(
          id: id, description: description, reminderTime: reminderTime);
      await load();
      // Reschedule with the correct data
      final updated = state.reminders.firstWhere((r) => r.id == id);
      await LocalNotificationService.cancelReminder(id);
      await LocalNotificationService.scheduleReminder(
        id: updated.id,
        description: updated.description,
        reminderTime: updated.reminderTime,
      );
    } catch (e, st) {
      dev.log('RemindersCubit update error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not update reminder.'));
    }
  }

  Future<void> delete(int id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.delete(id);
      await LocalNotificationService.cancelReminder(id);
      await load();
    } catch (e, st) {
      dev.log('RemindersCubit delete error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not delete reminder.'));
    }
  }

  Future<void> markTriggered(int id) async {
    try {
      await repository.markTriggered(id);
      await load();
    } catch (e, st) {
      dev.log('RemindersCubit markTriggered error', error: e, stackTrace: st);
    }
  }

  void toggleSelection(int id) {
    final selectedIds = Set<int>.from(state.selectedIds);
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    emit(state.copyWith(selectedIds: selectedIds));
  }

  void clearSelection() {
    emit(state.copyWith(selectedIds: const {}));
  }

  Future<void> deleteSelected() async {
    if (state.selectedIds.isEmpty) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      for (final id in state.selectedIds) {
        await repository.delete(id);
        await LocalNotificationService.cancelReminder(id);
      }
      emit(state.copyWith(selectedIds: const {}));
      await load();
    } catch (e, st) {
      dev.log('RemindersCubit deleteSelected error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not delete reminders.'));
    }
  }
}