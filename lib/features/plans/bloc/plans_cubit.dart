import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/local_notification_service.dart';
import '../../../data/database/database.dart';
import '../../../data/database/tables.dart';
import 'plans_state.dart';

class PlansCubit extends Cubit<PlansState> {
  final AppDatabase db;

  PlansCubit({required this.db})
      : super(PlansState(selectedDate: DateTime.now()));

  Future<void> loadAllEvents() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final events = await db.select(db.events).get();
      final data = events
          .map((e) => CalendarEventData(
                id: e.id,
                title: e.title,
                eventDate: e.eventDate,
                eventTime: e.eventTime,
                reminderTime: e.reminderTime,
                createdAt: e.createdAt,
              ))
          .toList();
      emit(state.copyWith(isLoading: false, events: data));
    } catch (e, st) {
      dev.log('PlansCubit loadAllEvents error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not load events.'));
    }
  }

  Future<void> loadEvents() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final start = DateTime.utc(
        state.selectedDate.year,
        state.selectedDate.month,
        state.selectedDate.day,
      );
      final end = start.add(const Duration(days: 1));
      final events = await (db.select(db.events)
            ..where((t) => t.eventDate.isBetweenValues(start, end)))
          .get();

      final data = events
          .map((e) => CalendarEventData(
                id: e.id,
                title: e.title,
                eventDate: e.eventDate,
                eventTime: e.eventTime,
                reminderTime: e.reminderTime,
                createdAt: e.createdAt,
              ))
          .toList();
      emit(state.copyWith(isLoading: false, events: data));
    } catch (e, st) {
      dev.log('PlansCubit loadEvents error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not load events.'));
    }
  }

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
    loadEvents();
  }

  Future<void> addEvent({
    required String title,
    required DateTime eventDate,
    DateTime? eventTime,
    DateTime? reminderTime,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final newId = await db.into(db.events).insert(
            EventsCompanion.insert(
              title: title,
              eventDate: eventDate,
              eventTime:
                  eventTime != null ? Value(eventTime) : Value.absent(),
              reminderTime: reminderTime != null
                  ? Value(reminderTime)
                  : Value.absent(),
            ),
          );
      await loadAllEvents();

      if (reminderTime != null) {
        await LocalNotificationService.scheduleEventReminder(
          id: newId,
          title: title,
          reminderTime: reminderTime,
        );
      }
    } catch (e, st) {
      dev.log('PlansCubit addEvent error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not add event.'));
    }
  }

  Future<void> updateEvent({
    required int id,
    required String title,
    required DateTime eventDate,
    DateTime? eventTime,
    DateTime? reminderTime,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await (db.update(db.events)..where((t) => t.id.equals(id))).write(
            EventsCompanion(
              title: Value(title),
              eventDate: Value(eventDate),
              eventTime: eventTime != null
                  ? Value(eventTime)
                  : Value.absent(),
              reminderTime: reminderTime != null
                  ? Value(reminderTime)
                  : Value.absent(),
            ),
          );
      await loadAllEvents();

      await LocalNotificationService.cancelEventReminder(id);
      if (reminderTime != null) {
        await LocalNotificationService.scheduleEventReminder(
          id: id,
          title: title,
          reminderTime: reminderTime,
        );
      }
    } catch (e, st) {
      dev.log('PlansCubit updateEvent error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not update event.'));
    }
  }

  Future<void> deleteEvent(int id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await (db.delete(db.events)..where((t) => t.id.equals(id))).go();
      await LocalNotificationService.cancelEventReminder(id);
      await loadAllEvents();
    } catch (e, st) {
      dev.log('PlansCubit deleteEvent error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not delete event.'));
    }
  }
}