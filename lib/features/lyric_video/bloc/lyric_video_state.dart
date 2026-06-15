import 'package:equatable/equatable.dart';

import '../models/lyric_line.dart';

enum LyricVideoStep {
  idle,
  searching,
  ready,
  syncing,
  rendering,
  done,
  error,
}

enum LyricAnimationStyle {
  wordByWord,
  lineByLine,
  fillUp,
  fadeIn,
  bounce,
  typewriter,
  wave,
  glitch,
  drop,
  shine,
  zoomIn,
  slideUp,
  rotate,
  heartbeat,
}

class LyricVideoState extends Equatable {
  final LyricVideoStep step;
  final String searchQuery;
  final bool isSearching;
  final String? localAudioPath;
  final String? backgroundVideoPath;
  final List<LyricLine> lyrics;
  final Duration playbackPosition;
  final Duration playbackDuration;
  final bool isPlaying;
  final int activeLyricIndex;
  final double glassOpacity;
  final double blurIntensity;
  final String glassColorHex;
  final int snippetDurationSeconds;
  final int startPositionMs;
  final int videoStartMs;
  final LyricAnimationStyle animationStyle;
  final double renderProgress;          // 0.0 – 1.0
  final String? renderedVideoPath;
  final String? errorMessage;

  const LyricVideoState({
    this.step = LyricVideoStep.idle,
    this.searchQuery = '',
    this.isSearching = false,
    this.localAudioPath,
    this.backgroundVideoPath,
    this.lyrics = const [],
    this.playbackPosition = Duration.zero,
    this.playbackDuration = Duration.zero,
    this.isPlaying = false,
    this.activeLyricIndex = -1,
    this.glassOpacity = 0.18,
    this.blurIntensity = 20.0,
    this.glassColorHex = '#D81B60',
    this.snippetDurationSeconds = 30,
    this.startPositionMs = 0,
    this.videoStartMs = 0,
    this.animationStyle = LyricAnimationStyle.wordByWord,
    this.renderProgress = 0.0,
    this.renderedVideoPath,
    this.errorMessage,
  });

  LyricVideoState copyWith({
    LyricVideoStep? step,
    String? searchQuery,
    bool? isSearching,
    String? localAudioPath,
    bool clearLocalAudioPath = false,
    String? backgroundVideoPath,
    bool clearBackgroundVideoPath = false,
    List<LyricLine>? lyrics,
    Duration? playbackPosition,
    Duration? playbackDuration,
    bool? isPlaying,
    int? activeLyricIndex,
    double? glassOpacity,
    double? blurIntensity,
    String? glassColorHex,
    int? snippetDurationSeconds,
    int? startPositionMs,
    int? videoStartMs,
    LyricAnimationStyle? animationStyle,
    double? renderProgress,
    String? renderedVideoPath,
    bool clearRenderedVideoPath = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LyricVideoState(
      step: step ?? this.step,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      localAudioPath:
          clearLocalAudioPath ? null : localAudioPath ?? this.localAudioPath,
      backgroundVideoPath: clearBackgroundVideoPath
          ? null
          : backgroundVideoPath ?? this.backgroundVideoPath,
      lyrics: lyrics ?? this.lyrics,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      playbackDuration: playbackDuration ?? this.playbackDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      activeLyricIndex: activeLyricIndex ?? this.activeLyricIndex,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      glassColorHex: glassColorHex ?? this.glassColorHex,
      snippetDurationSeconds:
          snippetDurationSeconds ?? this.snippetDurationSeconds,
      startPositionMs: startPositionMs ?? this.startPositionMs,
      videoStartMs: videoStartMs ?? this.videoStartMs,
      animationStyle: animationStyle ?? this.animationStyle,
      renderProgress: renderProgress ?? this.renderProgress,
      renderedVideoPath: clearRenderedVideoPath
          ? null
          : renderedVideoPath ?? this.renderedVideoPath,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        step,
        searchQuery,
        isSearching,
        localAudioPath,
        backgroundVideoPath,
        lyrics,
        playbackPosition,
        playbackDuration,
        isPlaying,
        activeLyricIndex,
        glassOpacity,
        blurIntensity,
        glassColorHex,
        snippetDurationSeconds,
        startPositionMs,
        videoStartMs,
        animationStyle,
        renderProgress,
        renderedVideoPath,
        errorMessage,
      ];
}