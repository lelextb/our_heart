// lib/features/plans/bloc/plans_state.dart

import 'package:equatable/equatable.dart';

/// Represents the state of the Plans feature (calendar events and reminders).
class PlansState extends Equatable {
  final List<CalendarEventData> events;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;

  const PlansState({
    this.events = const [],
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });

  PlansState copyWith({
    List<CalendarEventData>? events,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlansState(
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [events, selectedDate, isLoading, errorMessage];
}

class CalendarEventData extends Equatable {
  final int id;
  final String title;
  final DateTime eventDate;
  final DateTime? eventTime;
  final DateTime? reminderTime;
  final DateTime createdAt;

  const CalendarEventData({
    required this.id,
    required this.title,
    required this.eventDate,
    this.eventTime,
    this.reminderTime,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, eventDate, eventTime, reminderTime, createdAt];
}