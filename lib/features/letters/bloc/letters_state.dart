// lib/features/letters/bloc/letters_state.dart

import 'package:equatable/equatable.dart';

class LettersState extends Equatable {
  final List<LetterData> letters;
  final bool isLoading;
  final String? errorMessage;

  const LettersState({
    this.letters = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LettersState copyWith({
    List<LetterData>? letters,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LettersState(
      letters: letters ?? this.letters,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [letters, isLoading, errorMessage];
}

class LetterData extends Equatable {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LetterData({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, content, createdAt, updatedAt];
}