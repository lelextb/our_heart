import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/tables.dart';

class ReminderRepository {
  final AppDatabase db;

  const ReminderRepository({required this.db});

  /// Returns all reminders sorted by reminder time (earliest first).
  Future<List<Reminder>> getAll() async {
    try {
      final reminders = await db.select(db.reminders).get();
      reminders.sort((a, b) => a.reminderTime.compareTo(b.reminderTime));
      return reminders;
    } catch (e, st) {
      dev.log('Failed to load reminders', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns only upcoming reminders (in the future, not triggered).
  Future<List<Reminder>> getUpcoming() async {
    final all = await getAll();
    final now = DateTime.now();
    return all.where((r) => r.reminderTime.isAfter(now) && !r.isTriggered).toList();
  }

  /// Inserts a new reminder and returns its generated id.
  Future<int> add({
    required String description,
    required DateTime reminderTime,
  }) async {
    try {
      return await db.into(db.reminders).insert(
            RemindersCompanion.insert(
                description: description, reminderTime: reminderTime),
          );
    } catch (e, st) {
      dev.log('Failed to add reminder', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing reminder.
  Future<void> update({
    required int id,
    String? description,
    DateTime? reminderTime,
    bool? isTriggered,
  }) async {
    try {
      final companion = RemindersCompanion(
        description:
            description != null ? Value(description) : Value.absent(),
        reminderTime:
            reminderTime != null ? Value(reminderTime) : Value.absent(),
        isTriggered:
            isTriggered != null ? Value(isTriggered) : Value.absent(),
      );
      await (db.update(db.reminders)..where((t) => t.id.equals(id)))
          .write(companion);
    } catch (e, st) {
      dev.log('Failed to update reminder $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a reminder by id.
  Future<void> delete(int id) async {
    try {
      await (db.delete(db.reminders)..where((t) => t.id.equals(id))).go();
    } catch (e, st) {
      dev.log('Failed to delete reminder $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Marks a reminder as triggered.
  Future<void> markTriggered(int id) async {
    await update(id: id, isTriggered: true);
  }
}