// lib/features/info/bloc/info_state.dart

import 'package:equatable/equatable.dart';

/// Represents the state of the Info feature (list of info entries).
class InfoState extends Equatable {
  final List<InfoEntryData> entries;
  final bool isLoading;
  final String? errorMessage;

  const InfoState({
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  InfoState copyWith({
    List<InfoEntryData>? entries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return InfoState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [entries, isLoading, errorMessage];
}

/// Lightweight model for Info entries exposed to the UI.
class InfoEntryData extends Equatable {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;

  const InfoEntryData({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, content, createdAt];
}