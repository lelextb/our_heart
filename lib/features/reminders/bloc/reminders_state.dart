import 'package:equatable/equatable.dart';

class RemindersState extends Equatable {
  final List<ReminderData> reminders;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> selectedIds; // for bulk delete

  const RemindersState({
    this.reminders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedIds = const {},
  });

  RemindersState copyWith({
    List<ReminderData>? reminders,
    bool? isLoading,
    String? errorMessage,
    Set<int>? selectedIds,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  @override
  List<Object?> get props => [reminders, isLoading, errorMessage, selectedIds];
}

class ReminderData extends Equatable {
  final int id;
  final String description;
  final DateTime reminderTime;
  final bool isTriggered;

  const ReminderData({
    required this.id,
    required this.description,
    required this.reminderTime,
    required this.isTriggered,
  });

  @override
  List<Object?> get props => [id, description, reminderTime, isTriggered];
}