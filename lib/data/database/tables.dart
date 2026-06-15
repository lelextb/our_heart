// lib/data/database/tables.dart

import 'package:drift/drift.dart';

/// Drift table definition for Info entries.
class InfoEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Drift table definition for Calendar events (Plans).
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get eventDate => dateTime()();
  DateTimeColumn get eventTime => dateTime().nullable()();
  DateTimeColumn get reminderTime => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Drift table definition for Reminders that are not tied to a calendar event.
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text().withLength(min: 1, max: 500)();
  DateTimeColumn get reminderTime => dateTime()();
  BoolColumn get isTriggered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Drift table definition for Letters written by the user.
class Letters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// Drift table definition for Gallery photo categories (albums).
/// Each category has a unique name and an optional description.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(name)'];
}

/// Drift table definition for Gallery photo metadata.
/// Each photo belongs to a category (via [categoryId]).
class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get filePath => text()();            // absolute path inside app‑private storage
  TextColumn get thumbnailPath => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}