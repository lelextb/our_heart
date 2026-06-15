// lib/features/lyric_video/bloc/lyric_video_cubit.dart

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/repositories/settings_repository.dart';
import '../models/lyric_line.dart';
import '../services/lyric_fetch_service.dart';
import 'lyric_video_state.dart';

class LyricVideoCubit extends Cubit<LyricVideoState> {
  LyricVideoCubit({required this.settingsRepo})
      : super(const LyricVideoState()) {
    dev.log('[LyricVideoCubit] constructor');
  }

  final SettingsRepository settingsRepo;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  final GlobalKey offscreenCardKey = GlobalKey();

  // ---- Import audio ----
  Future<void> importAudioFile() async {
    if (isClosed) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;
      await _player.setAudioSource(AudioSource.file(filePath));
      _listenToPlayer();
      emit(state.copyWith(
          localAudioPath: filePath, step: LyricVideoStep.idle));
    } catch (e, st) {
      dev.log('[LyricVideoCubit] importAudioFile error', error: e, stackTrace: st);
      emit(state.copyWith(
        step: LyricVideoStep.idle,
        errorMessage: 'Could not load audio file.',
      ));
    }
  }

  // ---- Import video (background) ----
  Future<void> importVideoFile() async {
    if (isClosed) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;
      emit(state.copyWith(
          backgroundVideoPath: filePath, step: LyricVideoStep.idle));
    } catch (e, st) {
      dev.log('[LyricVideoCubit] importVideoFile error', error: e, stackTrace: st);
      emit(state.copyWith(
        errorMessage: 'Could not load video file.',
      ));
    }
  }

  // ---- Lyrics search ----
  Future<void> searchLyrics(String query) async {
    if (isClosed) return;
    if (query.trim().isEmpty) return;
    emit(state.copyWith(
      step: LyricVideoStep.searching,
      searchQuery: query,
      isSearching: true,
      lyrics: const [],
      clearError: true,
    ));
    try {
      final parts = query.split('-');
      final trackName = parts.length > 1 ? parts[1].trim() : query.trim();
      final artistName = parts.length > 1 ? parts[0].trim() : '';
      List<LyricLine> lyrics;
      try {
        lyrics = await LyricFetchService.fetchLyrics(
          trackName: trackName,
          artistName: artistName.isNotEmpty ? artistName : trackName,
        );
      } catch (_) {
        final renResults = await LyricFetchService.searchRentanAdviser(query);
        if (renResults.isNotEmpty) {
          lyrics = await LyricFetchService.fetchLrcFromUrl(renResults.first.id);
        } else {
          throw Exception('No lyrics found');
        }
      }
      emit(state.copyWith(
        step: LyricVideoStep.ready,
        isSearching: false,
        lyrics: lyrics,
      ));
    } catch (e, st) {
      dev.log('[LyricVideoCubit] searchLyrics error', error: e, stackTrace: st);
      emit(state.copyWith(
        step: LyricVideoStep.idle,
        isSearching: false,
        errorMessage: 'Lyrics not found for "$query".',
      ));
    }
  }

  // ---- Import LRC ----
  Future<void> importLrcFile() async {
    if (isClosed) return;
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.any, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;
      final content = await File(filePath).readAsString();
      final parsed = LyricFetchService.parseLrc(content);
      if (parsed.isEmpty) {
        emit(state.copyWith(
          step: LyricVideoStep.idle,
          errorMessage: 'No valid timestamps found.',
        ));
        return;
      }
      emit(state.copyWith(
        step: LyricVideoStep.ready,
        lyrics: parsed,
        clearError: true,
      ));
    } catch (e, st) {
      dev.log('[LyricVideoCubit] importLrcFile error', error: e, stackTrace: st);
      emit(state.copyWith(
        step: LyricVideoStep.idle,
        errorMessage: 'Failed to read LRC file: $e',
      ));
    }
  }

  // ---- Playback ----
  void togglePlay() =>
      _player.playing ? _player.pause() : _player.play();
  void seek(Duration position) => _player.seek(position);
  void playPreview() {
    final startPos = Duration(milliseconds: state.startPositionMs);
    _player.seek(startPos);
    _player.play();
  }
  void syncLyricsNow() {
    if (isClosed) return;
    _syncLyrics(state.playbackPosition);
  }

  // ---- Sync lyrics (absolute position) ----
  void _syncLyrics(Duration position) {
    final lyrics = state.lyrics;
    if (lyrics.isEmpty) return;
    final effectivePos = position.inMilliseconds; // absolute – no extra offset
    int newIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (effectivePos >= lyrics[i].milliseconds) {
        newIndex = i;
      } else {
        break;
      }
    }
    if (newIndex != state.activeLyricIndex) {
      emit(state.copyWith(activeLyricIndex: newIndex));
    }
  }

  void _listenToPlayer() {
    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((pos) {
      emit(state.copyWith(playbackPosition: pos));
      _syncLyrics(pos);
      final snippetEndMs = state.startPositionMs + state.snippetDurationSeconds * 1000;
      if (pos.inMilliseconds >= snippetEndMs) {
        _player.pause();
        _player.seek(Duration(milliseconds: state.startPositionMs));
        emit(state.copyWith(isPlaying: false));
      }
    });
    _durationSub?.cancel();
    _durationSub = _player.durationStream.listen((dur) {
      emit(state.copyWith(playbackDuration: dur ?? Duration.zero));
    });
    _playerStateSub?.cancel();
    _playerStateSub = _player.playerStateStream.listen((ps) {
      emit(state.copyWith(isPlaying: ps.playing));
    });
  }

  // ---- Customization ----
  void setGlassOpacity(double o) => emit(state.copyWith(glassOpacity: o.clamp(0.0, 1.0)));
  void setBlurIntensity(double b) => emit(state.copyWith(blurIntensity: b.clamp(0.0, 40.0)));
  void setGlassColorHex(String h) => emit(state.copyWith(glassColorHex: h));
  void setSnippetDuration(int s) => emit(state.copyWith(snippetDurationSeconds: s.clamp(5, 60)));
  void setStartPosition(int ms) {
    final maxStart = (state.playbackDuration.inMilliseconds - state.snippetDurationSeconds * 1000).clamp(0, double.infinity).toInt();
    emit(state.copyWith(startPositionMs: ms.clamp(0, maxStart)));
    _player.seek(Duration(milliseconds: ms));
  }
  void setAnimationStyle(LyricAnimationStyle style) => emit(state.copyWith(animationStyle: style));

  // ---------------------------------------------------------------------------
  // Composition rendering pipeline
  // ---------------------------------------------------------------------------
  static const int _captureFps = 15;
  static const int outputWidth = 1080;
  static const int outputHeight = 1920;

  Future<void> startRendering(BuildContext context) async {
    if (isClosed) return;
    dev.log('[LyricVideoCubit] startRendering');
    if (state.localAudioPath == null && state.backgroundVideoPath == null) {
      emit(state.copyWith(errorMessage: 'At least an audio file or a video file is required.'));
      return;
    }
    if (state.lyrics.isEmpty) {
      emit(state.copyWith(errorMessage: 'No lyrics loaded.'));
      return;
    }

    // Permission check
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (await Permission.microphone.isPermanentlyDenied) {
          if (context.mounted) {
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Microphone Access Required'),
                content: const Text('Microphone access is required to record audio for the video.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () { Navigator.pop(ctx, true); openAppSettings(); }, child: const Text('Open Settings')),
                ],
              ),
            );
          }
        }
        emit(state.copyWith(errorMessage: 'Microphone permission is required.', renderProgress: 0.0));
        return;
      }
    }

    emit(state.copyWith(step: LyricVideoStep.rendering, renderProgress: 0.0, clearError: true));

    try {
      final tempDir = await getTemporaryDirectory();
      final workDir = p.join(tempDir.path, 'lyric_composite_${DateTime.now().millisecondsSinceEpoch}');
      await Directory(workDir).create(recursive: true);

      final targetDuration = state.snippetDurationSeconds;
      final audioPath = state.localAudioPath;
      final videoPath = state.backgroundVideoPath;

      // 1. Prepare background video
      String bgVideoPath;
      if (videoPath != null) {
        bgVideoPath = await _prepareBackgroundVideo(videoPath, targetDuration, workDir);
      } else {
        bgVideoPath = await _createBlankBackground(targetDuration, workDir);
      }

      // 2. Generate lyric card frames
      final framesDir = p.join(workDir, 'frames');
      await Directory(framesDir).create();
      dev.log('[LyricVideoCubit] frames dir: $framesDir');
      final totalFrames = targetDuration * _captureFps;

      // Initial delay for layout
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));

      for (int i = 0; i < totalFrames; i++) {
        // Absolute timestamp for this frame
        final absMs = state.startPositionMs + (i * 1000 / _captureFps).round();
        emit(state.copyWith(playbackPosition: Duration(milliseconds: absMs)));
        _syncLyrics(Duration(milliseconds: absMs));

        // Wait for frame to be painted
        await WidgetsBinding.instance.endOfFrame;
        await _captureCardFrame(framesDir, i);

        final progress = (i + 1) / totalFrames;
        emit(state.copyWith(renderProgress: progress));
      }

      // Verify frames were created
      final frameFiles = Directory(framesDir).listSync().whereType<File>().toList();
      dev.log('[LyricVideoCubit] captured ${frameFiles.length} frames');
      if (frameFiles.isEmpty) {
        throw Exception('No frames captured. The card may not have rendered.');
      }

      // 3. Composite with FFmpeg
      final outputVideo = p.join(workDir, 'lyric_final.mp4');
      await _compositeVideo(bgVideoPath, framesDir, audioPath, targetDuration, outputVideo);

      emit(state.copyWith(
        step: LyricVideoStep.done,
        renderedVideoPath: outputVideo,
        renderProgress: 1.0,
      ));
    } catch (e, st) {
      dev.log('[LyricVideoCubit] rendering error', error: e, stackTrace: st);
      emit(state.copyWith(
        step: LyricVideoStep.error,
        errorMessage: 'Rendering failed: $e',
        renderProgress: 0.0,
      ));
    }
  }

  Future<String> _prepareBackgroundVideo(String videoPath, int targetDurationSec, String workDir) async {
    final durationSec = await _getVideoDuration(videoPath);
    final target = targetDurationSec.toDouble();
    final output = p.join(workDir, 'bg_processed.mp4');

    if (durationSec >= target) {
      final cmd = '-y -ss ${state.videoStartMs / 1000.0} -t $target -i "$videoPath" -an -c:v libx264 -pix_fmt yuv420p "$output"';
      dev.log('[LyricVideoCubit] trim bg: $cmd');
      await _executeFFmpeg(cmd);
    } else {
      final speedFactor = target / durationSec;
      final cmd = '-y -i "$videoPath" -an -vf "setpts=${speedFactor}*PTS" -c:v libx264 -pix_fmt yuv420p "$output"';
      dev.log('[LyricVideoCubit] slow down bg: $cmd');
      await _executeFFmpeg(cmd);
    }
    return output;
  }

  Future<String> _createBlankBackground(int targetDurationSec, String workDir) async {
    final output = p.join(workDir, 'bg_blank.mp4');
    final cmd = '-y -f lavfi -i color=c=black:s=${outputWidth}x${outputHeight}:d=$targetDurationSec -c:v libx264 -pix_fmt yuv420p "$output"';
    dev.log('[LyricVideoCubit] blank bg: $cmd');
    await _executeFFmpeg(cmd);
    return output;
  }

  Future<void> _captureCardFrame(String framesDir, int index) async {
    try {
      final boundary = offscreenCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        dev.log('[LyricVideoCubit] capture: boundary null at frame $index');
        return;
      }
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final file = File(p.join(framesDir, 'frame_${index.toString().padLeft(6, '0')}.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      dev.log('[LyricVideoCubit] frame $index saved: ${file.lengthSync()} bytes');
    } catch (e) {
      dev.log('[LyricVideoCubit] frame capture error: $e');
    }
  }

  Future<void> _compositeVideo(String bgVideoPath, String framesDir, String? audioPath, int targetDurationSec, String output) async {
    String audioSource = audioPath ?? bgVideoPath;
    if (audioPath == null && state.backgroundVideoPath != null) {
      audioSource = await _extractAudioFromVideo(state.backgroundVideoPath!, targetDurationSec, framesDir);
    } else if (audioPath == null) {
      audioSource = await _generateSilenceAudio(targetDurationSec, framesDir);
    } else {
      audioSource = await _extractAudioSnippet(audioPath, targetDurationSec, framesDir);
    }

    final framePattern = p.join(framesDir, 'frame_%06d.png');
    final cmd = '-y -i "$bgVideoPath" -framerate $_captureFps -i "$framePattern" '
        '-i "$audioSource" -filter_complex "[1:v]format=rgba,colorchannelmixer=aa=1[card];[0:v][card]overlay=(W-w)/2:(H-h)/2:format=auto,format=yuv420p" '
        '-c:v libx264 -c:a aac -shortest -map 2:a "$output"';
    dev.log('[LyricVideoCubit] composite: $cmd');
    await _executeFFmpeg(cmd);
  }

  Future<String> _extractAudioSnippet(String audioPath, int targetDurationSec, String workDir) async {
    final output = p.join(workDir, 'audio_snippet.m4a');
    final startSec = state.startPositionMs / 1000.0;
    final cmd = '-y -ss $startSec -t $targetDurationSec -i "$audioPath" -vn -c:a aac -b:a 192k "$output"';
    await _executeFFmpeg(cmd);
    return output;
  }

  Future<String> _extractAudioFromVideo(String videoPath, int targetDurationSec, String workDir) async {
    final output = p.join(workDir, 'video_audio_snippet.m4a');
    final startSec = state.videoStartMs / 1000.0;
    final cmd = '-y -ss $startSec -t $targetDurationSec -i "$videoPath" -vn -c:a aac -b:a 192k "$output"';
    await _executeFFmpeg(cmd);
    return output;
  }

  Future<String> _generateSilenceAudio(int targetDurationSec, String workDir) async {
    final output = p.join(workDir, 'silence.m4a');
    final cmd = '-y -f lavfi -i anullsrc=r=44100:cl=stereo -t $targetDurationSec -c:a aac "$output"';
    await _executeFFmpeg(cmd);
    return output;
  }

  Future<double> _getVideoDuration(String videoPath) async {
    final session = await FFprobeKit.execute('-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$videoPath"');
    final output = await session.getOutput();
    return double.tryParse(output?.trim() ?? '0') ?? 0.0;
  }

  Future<void> _executeFFmpeg(String cmd) async {
    final session = await FFmpegKit.execute(cmd);
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg command failed: $logs');
    }
  }

  Future<String?> downloadVideoToDownloads() async {
    final sourcePath = state.renderedVideoPath;
    if (sourcePath == null || !File(sourcePath).existsSync()) return null;
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final destPath = p.join(appDir.path, 'OurHeart_LyricVideo.mp4');
        await File(sourcePath).copy(destPath);
        return destPath;
      }
      final destPath = p.join(downloadsDir.path,
          'OurHeart_LyricVideo_${DateTime.now().millisecondsSinceEpoch}.mp4');
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e, st) {
      dev.log('[LyricVideoCubit] download error', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> shareVideo() async {
    final path = state.renderedVideoPath;
    if (path == null || !File(path).existsSync()) return;
    await Share.shareXFiles([XFile(path)], text: 'Created with Our Heart');
  }

  void resetRender() {
    emit(state.copyWith(
      step: LyricVideoStep.ready,
      renderProgress: 0.0,
      renderedVideoPath: null,
    ));
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    return super.close();
  }
}