// lib/data/repositories/letter_repository.dart

import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/tables.dart';

/// Repository for managing Letter entities in the local database.
class LetterRepository {
  final AppDatabase db;

  const LetterRepository({required this.db});

  /// Returns all letters ordered by creation date descending (most recent first).
  Future<List<Letter>> getAll() async {
    try {
      final letters = await db.letters.select().get();
      letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return letters;
    } catch (e, st) {
      dev.log('Failed to load letters', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns a single letter by [id], or `null` if not found.
  Future<Letter?> getById(int id) async {
    try {
      return await (db.select(db.letters)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e, st) {
      dev.log('Failed to fetch letter $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Creates a new letter.
  Future<void> add({required String title, required String content}) async {
    try {
      await db.into(db.letters).insert(
            LettersCompanion.insert(title: title, content: content),
          );
    } catch (e, st) {
      dev.log('Failed to insert letter', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates an existing letter identified by [id].
  Future<void> update({
    required int id,
    required String title,
    required String content,
  }) async {
    try {
      await (db.update(db.letters)..where((t) => t.id.equals(id))).write(
            LettersCompanion(
              title: Value(title),
              content: Value(content),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } catch (e, st) {
      dev.log('Failed to update letter $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes the letter identified by [id].
  Future<void> delete(int id) async {
    try {
      await (db.delete(db.letters)..where((t) => t.id.equals(id))).go();
    } catch (e, st) {
      dev.log('Failed to delete letter $id', error: e, stackTrace: st);
      rethrow;
    }
  }
}