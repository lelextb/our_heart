// lib/data/repositories/info_repository.dart

import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/tables.dart';

/// Repository for Info entries, providing a clean API for the
/// Info feature's state management.
class InfoRepository {
  final AppDatabase db;

  const InfoRepository({required this.db});

  /// Returns all info entries ordered by creation date descending.
  Future<List<InfoEntry>> getAll() async {
    try {
      final entries = await db.infoEntries.select().get();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (e, st) {
      dev.log('Failed to load info entries', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns a single entry by its [id], or `null` if not found.
  Future<InfoEntry?> getById(int id) async {
    try {
      return await (db.select(db.infoEntries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e, st) {
      dev.log('Failed to fetch info entry $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Inserts a new info entry.
  Future<void> add({required String title, required String content}) async {
    try {
      await db.into(db.infoEntries).insert(
            InfoEntriesCompanion.insert(title: title, content: content),
          );
    } catch (e, st) {
      dev.log('Failed to insert info entry', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing entry identified by [id].
  Future<void> update({
    required int id,
    required String title,
    required String content,
  }) async {
    try {
      await (db.update(db.infoEntries)..where((t) => t.id.equals(id))).write(
            InfoEntriesCompanion(
              title: Value(title),
              content: Value(content),
            ),
          );
    } catch (e, st) {
      dev.log('Failed to update info entry $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes the entry identified by [id].
  Future<void> delete(int id) async {
    try {
      await (db.delete(db.infoEntries)..where((t) => t.id.equals(id))).go();
    } catch (e, st) {
      dev.log('Failed to delete info entry $id', error: e, stackTrace: st);
      rethrow;
    }
  }
}