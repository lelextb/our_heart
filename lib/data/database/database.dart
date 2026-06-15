// lib/data/database/database.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [InfoEntries, Events, Reminders, Letters, Categories, Photos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Create the categories table
            await m.createTable(categories);
            // Recreate the photos table with the new categoryId column
            // Drop old photos table if exists – data loss acceptable for development
            await m.deleteTable('photos');
            await m.createTable(photos);
          }
        },
        beforeOpen: (details) async {
          // Ensure foreign keys are enabled
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'our_heart.db'));
      return NativeDatabase.createInBackground(dbFile);
    });
  }
}