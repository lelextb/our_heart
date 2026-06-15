// lib/features/lyric_video/lyric_video_page.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/settings_repository.dart';
import 'bloc/lyric_video_cubit.dart';
import 'bloc/lyric_video_state.dart';
import 'models/lyric_line.dart';

class LyricVideoPage extends StatelessWidget {
  const LyricVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => LyricVideoCubit(
        settingsRepo: ctx.read<SettingsRepository>(),
      ),
      child: const _LyricVideoBody(),
    );
  }
}

class _LyricVideoBody extends StatelessWidget {
  const _LyricVideoBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Lyric Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import LRC file',
            onPressed: () => context.read<LyricVideoCubit>().importLrcFile(),
          ),
        ],
      ),
      body: BlocBuilder<LyricVideoCubit, LyricVideoState>(
        builder: (context, state) {
          final cubit = context.read<LyricVideoCubit>();
          final isRendering = state.step == LyricVideoStep.rendering;
          final isDone = state.step == LyricVideoStep.done;

          // Final overlay size after 3× scale: 1440 × 900
          const double scaleFactor = 3.0;
          const double captureWidth = 480;
          const double captureHeight = 300;

          final screenHeight = MediaQuery.of(context).size.height;
          final previewHeight = screenHeight * 0.40;

          return Stack(
            children: [
              // ---------- Off‑screen capture card (always painted, far away) ----------
              Positioned(
                left: -3000,
                top: -3000,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: scaleFactor,
                    child: SizedBox(
                      width: captureWidth,
                      height: captureHeight,
                      child: RepaintBoundary(
                        key: cubit.offscreenCardKey,
                        child: _GlassLyricCard(
                          state: state,
                          forCapture: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --------------------- Foreground UI ---------------------
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.audio_file, size: 18),
                                  label: Text(state.localAudioPath != null
                                      ? 'Audio ready'
                                      : 'Audio'),
                                  onPressed: () => cubit.importAudioFile(),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.video_file, size: 18),
                                  label: Text(state.backgroundVideoPath != null
                                      ? 'Video ready'
                                      : 'Video'),
                                  onPressed: () => cubit.importVideoFile(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search lyrics...',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                              ),
                              onSubmitted: (q) => cubit.searchLyrics(q),
                            ),
                          ],
                        ),
                      ),
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (state.localAudioPath != null &&
                          state.playbackDuration.inMilliseconds > 0 &&
                          !isRendering &&
                          !isDone)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.tune),
                            label: Text(
                              'Select part (${_formatMs(state.startPositionMs)} - ${_formatMs(state.startPositionMs + state.snippetDurationSeconds * 1000)})',
                            ),
                            onPressed: () =>
                                _showPartSelectorSheet(context, state),
                          ),
                        ),
                      // On‑screen preview card
                      SizedBox(
                        height: previewHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _GlassLyricCard(state: state),
                        ),
                      ),
                      if (!isRendering && state.localAudioPath != null)
                        _AudioControls(state: state),
                      if (!isRendering &&
                          !isDone &&
                          (state.localAudioPath != null ||
                              state.backgroundVideoPath != null) &&
                          state.lyrics.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.movie),
                            label: const Text('Render Lyric Video'),
                            onPressed: () => cubit.startRendering(context),
                          ),
                        ),
                      if (isRendering)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              GlassmorphicContainer(
                                blurSigmaX: 8,
                                blurSigmaY: 8,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value: state.renderProgress,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rendering ${(state.renderProgress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isDone)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 28),
                                  const SizedBox(width: 8),
                                  const Text('Video ready!',
                                      style: TextStyle(
                                          color: Colors.green, fontSize: 18)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text('Save'),
                                    onPressed: () async {
                                      final path =
                                          await cubit.downloadVideoToDownloads();
                                      if (path != null && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Saved to $path')));
                                      }
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                    onPressed: () => cubit.shareVideo(),
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('New'),
                                    onPressed: () => cubit.resetRender(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---- Color helpers ----
Color _darkenColor(Color color, double amount) {
  return Color.fromARGB(
    color.alpha,
    (color.red * amount).round(),
    (color.green * amount).round(),
    (color.blue * amount).round(),
  );
}

Color _lightenColor(Color color, double amount) {
  return Color.fromARGB(
    color.alpha,
    (color.red + (255 - color.red) * amount).round(),
    (color.green + (255 - color.green) * amount).round(),
    (color.blue + (255 - color.blue) * amount).round(),
  );
}

// ---- Glass progress bar ----
class _GlassProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final int startMs;
  final int snippetMs;
  final ValueChanged<Duration>? onSeek;

  const _GlassProgressBar({
    required this.position,
    required this.duration,
    required this.startMs,
    required this.snippetMs,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return const SizedBox.shrink();

    final snippetEndMs = startMs + snippetMs;
    final relativePos = position.inMilliseconds;

    double fillFraction = 0.0;
    if (relativePos >= startMs && relativePos <= snippetEndMs) {
      fillFraction = (relativePos - startMs) / snippetMs;
    } else if (relativePos > snippetEndMs) {
      fillFraction = 1.0;
    }

    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final tapX = details.localPosition.dx;
        final width = box.size.width;
        final fraction = (tapX / width).clamp(0.0, 1.0);
        final targetMs = startMs + (fraction * snippetMs).round();
        onSeek?.call(Duration(milliseconds: targetMs));
      },
      child: GlassmorphicContainer(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fillFraction,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            if (fillFraction > 0 && fillFraction < 1.0)
              Positioned(
                left: fillFraction *
                        (MediaQuery.of(context).size.width - 64) -
                    2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Audio controls ----
class _AudioControls extends StatelessWidget {
  final LyricVideoState state;
  const _AudioControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LyricVideoCubit>();
    final isPlaying = state.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40),
                onPressed: cubit.togglePlay,
              ),
              IconButton(
                icon: const Icon(Icons.preview, size: 28),
                tooltip: 'Preview snippet',
                onPressed: cubit.playPreview,
              ),
              Expanded(
                child: _GlassProgressBar(
                  position: state.playbackPosition,
                  duration: state.playbackDuration,
                  startMs: state.startPositionMs,
                  snippetMs: state.snippetDurationSeconds * 1000,
                  onSeek: (pos) => cubit.seek(pos),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _showCustomizationSheet(context, state),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showPartSelectorSheet(BuildContext context, LyricVideoState state) {
  final cubit = context.read<LyricVideoCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return BlocProvider.value(
        value: cubit,
        child: const _PartSelectorSheetContent(),
      );
    },
  );
}

class _PartSelectorSheetContent extends StatefulWidget {
  const _PartSelectorSheetContent();

  @override
  State<_PartSelectorSheetContent> createState() =>
      _PartSelectorSheetContentState();
}

class _PartSelectorSheetContentState
    extends State<_PartSelectorSheetContent> {
  late double _startValue;

  @override
  void initState() {
    super.initState();
    final state = context.read<LyricVideoCubit>().state;
    _startValue = state.startPositionMs.toDouble();
  }

  void _updateStart(double value) {
    setState(() => _startValue = value);
    context.read<LyricVideoCubit>().setStartPosition(value.round());
    context.read<LyricVideoCubit>().playPreview();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LyricVideoCubit>();
    final totalMs = cubit.state.playbackDuration.inMilliseconds;
    final snippetMs = cubit.state.snippetDurationSeconds * 1000;
    final maxStart = (totalMs - snippetMs).clamp(0, totalMs).toDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (ctx, scrollController) {
        return GlassmorphicContainer(
          blurSigmaX: 20,
          blurSigmaY: 20,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          borderColor: AppColors.primary.withOpacity(0.4),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select snippet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Update'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width - 32, 120),
                    painter: _WaveformPainter(
                        progress:
                            _startValue / totalMs.clamp(1, double.infinity)),
                  ),
                ),
              ),
              Slider(
                value: _startValue.clamp(0.0, maxStart),
                min: 0,
                max: maxStart > 0 ? maxStart : 1,
                onChanged: _updateStart,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatMs(_startValue.round()),
                      style: const TextStyle(color: Colors.white)),
                  Text(
                      _formatMs((_startValue.round() + snippetMs)
                          .clamp(0, totalMs)),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatMs(int ms) {
  final totalSec = ms ~/ 1000;
  final min = totalSec ~/ 60;
  final sec = totalSec % 60;
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 2;
    final random = Random(42);
    const barWidth = 4.0;
    final barCount = (size.width / barWidth).floor();
    for (int i = 0; i < barCount; i++) {
      double heightRatio = 0.2 + random.nextDouble() * 0.8;
      paint.color = i / barCount <= progress
          ? AppColors.primary.withOpacity(0.8)
          : Colors.white.withOpacity(0.3);
      canvas.drawLine(
        Offset(i * barWidth, size.height),
        Offset(i * barWidth, size.height * (1 - heightRatio)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

void _showCustomizationSheet(BuildContext context, LyricVideoState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return BlocProvider.value(
        value: context.read<LyricVideoCubit>(),
        child: const _CustomizationSheetContent(),
      );
    },
  );
}

class _CustomizationSheetContent extends StatelessWidget {
  const _CustomizationSheetContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricVideoCubit, LyricVideoState>(
      builder: (context, state) {
        final cubit = context.read<LyricVideoCubit>();
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (ctx, scrollController) {
            return GlassmorphicContainer(
              blurSigmaX: 20,
              blurSigmaY: 20,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              borderColor: AppColors.primary.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24)),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CustomRow(
                    label: 'Opacity',
                    value: state.glassOpacity,
                    min: 0.0,
                    max: 1.0,
                    onChanged: cubit.setGlassOpacity,
                  ),
                  _CustomRow(
                    label: 'Blur',
                    value: state.blurIntensity,
                    min: 0.0,
                    max: 40.0,
                    onChanged: cubit.setBlurIntensity,
                  ),
                  ListTile(
                    title: const Text('Glass Color',
                        style: TextStyle(color: Colors.white)),
                    trailing: GestureDetector(
                      onTap: () => _showColorPicker(context, cubit, state),
                      child: _buildColorPreview(state.glassColorHex),
                    ),
                  ),
                  _CustomRow(
                    label: 'Snippet (s)',
                    value: state.snippetDurationSeconds.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (v) => cubit.setSnippetDuration(v.round()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Animation Style',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _AnimationStyleGrid(
                    currentStyle: state.animationStyle,
                    onStyleSelected: (style) => cubit.setAnimationStyle(style),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---- Animation style selection grid ----
class _AnimationStyleGrid extends StatelessWidget {
  final LyricAnimationStyle currentStyle;
  final ValueChanged<LyricAnimationStyle> onStyleSelected;

  const _AnimationStyleGrid({
    required this.currentStyle,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final styles = LyricAnimationStyle.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        final isSelected = style == currentStyle;
        return GestureDetector(
          onTap: () => onStyleSelected(style),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconForStyle(style),
                  size: 18,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  _labelForStyle(style),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForStyle(LyricAnimationStyle style) {
    switch (style) {
      case LyricAnimationStyle.wordByWord:
        return Icons.text_fields;
      case LyricAnimationStyle.lineByLine:
        return Icons.view_headline;
      case LyricAnimationStyle.fillUp:
        return Icons.format_color_fill;
      case LyricAnimationStyle.fadeIn:
        return Icons.blur_on;
      case LyricAnimationStyle.bounce:
        return Icons.play_circle_outline;
      case LyricAnimationStyle.typewriter:
        return Icons.keyboard;
      case LyricAnimationStyle.wave:
        return Icons.waves;
      case LyricAnimationStyle.glitch:
        return Icons.broken_image;
      case LyricAnimationStyle.drop:
        return Icons.water_drop;
      case LyricAnimationStyle.shine:
        return Icons.auto_awesome;
      case LyricAnimationStyle.zoomIn:
        return Icons.zoom_in;
      case LyricAnimationStyle.slideUp:
        return Icons.vertical_align_top;
      case LyricAnimationStyle.rotate:
        return Icons.rotate_right;
      case LyricAnimationStyle.heartbeat:
        return Icons.favorite;
    }
  }

  String _labelForStyle(LyricAnimationStyle style) {
    switch (style) {
      case LyricAnimationStyle.wordByWord:
        return 'Word by Word';
      case LyricAnimationStyle.lineByLine:
        return 'Line by Line';
      case LyricAnimationStyle.fillUp:
        return 'Fill Up';
      case LyricAnimationStyle.fadeIn:
        return 'Fade In';
      case LyricAnimationStyle.bounce:
        return 'Bounce';
      case LyricAnimationStyle.typewriter:
        return 'Typewriter';
      case LyricAnimationStyle.wave:
        return 'Wave';
      case LyricAnimationStyle.glitch:
        return 'Glitch';
      case LyricAnimationStyle.drop:
        return 'Drop';
      case LyricAnimationStyle.shine:
        return 'Shine';
      case LyricAnimationStyle.zoomIn:
        return 'Zoom In';
      case LyricAnimationStyle.slideUp:
        return 'Slide Up';
      case LyricAnimationStyle.rotate:
        return 'Rotate';
      case LyricAnimationStyle.heartbeat:
        return 'Heartbeat';
    }
  }
}

Widget _buildColorPreview(String glassColorHex) {
  final isGradient = glassColorHex.contains('->');
  if (isGradient) {
    final colors = glassColorHex
        .split('->')
        .map((c) => Color(int.parse(c.trim().replaceFirst('#', '0xFF'))))
        .toList();
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white),
      ),
    );
  }
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: Color(int.parse(glassColorHex.replaceFirst('#', '0xFF'))),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white),
    ),
  );
}

Color _primaryColorFromHex(String glassColorHex) {
  if (glassColorHex.contains('->')) {
    final firstHex = glassColorHex.split('->').first.trim();
    return Color(int.parse(firstHex.replaceFirst('#', '0xFF')));
  }
  return Color(int.parse(glassColorHex.replaceFirst('#', '0xFF')));
}

void _showColorPicker(
    BuildContext context, LyricVideoCubit cubit, LyricVideoState state) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Glass Color'),
      content: Wrap(
        spacing: 8,
        children: [
          '#D81B60',
          '#FF4081',
          '#FF6B81',
          '#FFD700',
          '#00E676',
          '#40C4FF',
          '#7C4DFF',
          '#FF1744',
          '#00B0FF',
          '#FF6D00',
          '#C6FF00',
          '#D500F9',
          '#FFAB40',
          '#18FFFF',
          '#FF3D00',
          '#76FF03',
          '#E040FB',
          '#69F0AE',
          '#D81B60 -> #FFD700',
          '#FF4081 -> #7C4DFF',
          '#00E676 -> #40C4FF',
          '#FF6D00 -> #FFAB40',
          '#C6FF00 -> #18FFFF',
          '#D500F9 -> #76FF03',
          '#FF3D00 -> #E040FB',
          '#69F0AE -> #FF4081',
        ].map((hex) {
          final isGradient = hex.contains('->');
          final color = isGradient
              ? AppColors.primary
              : Color(int.parse(hex.replaceFirst('#', '0xFF')));
          return GestureDetector(
            onTap: () {
              cubit.setGlassColorHex(hex);
              Navigator.pop(ctx);
            },
            child: Container(
              width: isGradient ? 80 : 40,
              height: 40,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: isGradient
                    ? LinearGradient(
                        colors: hex
                            .split('->')
                            .map((c) => Color(int.parse(
                                c.trim().replaceFirst('#', '0xFF'))))
                            .toList(),
                      )
                    : null,
                color: isGradient ? null : color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

class _CustomRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _CustomRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: SizedBox(
        width: 160,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Glass lyric card – with forCapture flag (no extra internal scaling)
// ---------------------------------------------------------------------------
class _GlassLyricCard extends StatelessWidget {
  final LyricVideoState state;
  final bool forCapture;

  const _GlassLyricCard({required this.state, this.forCapture = false});

  @override
  Widget build(BuildContext context) {
    final glassColor = _primaryColorFromHex(state.glassColorHex);
    final settingsRepo = context.read<SettingsRepository>();

    final double avatarScale = forCapture ? 1.6 : 1.0;
    final avatarRadius = 28.0 * avatarScale;
    final nameFontSize = 16.0;
    final subFontSize = 13.0;
    final lyricActiveFontSize = 26.0;
    final lyricInactiveFontSize = 20.0;
    final lyricLineFontSize = 24.0;
    final paddingAll = 16.0;
    final blurRadius = forCapture ? state.blurIntensity * 2.0 : state.blurIntensity;
    final infoColor = _lightenColor(glassColor, 0.7);

    final Widget card = Column(
      children: [
        _LyricHeader(
          state: state,
          settingsRepo: settingsRepo,
          avatarRadius: avatarRadius,
          nameFontSize: nameFontSize,
          subFontSize: subFontSize,
          infoColor: infoColor,
        ),
        SizedBox(height: 12),
        Expanded(
          child: state.lyrics.isEmpty
              ? Center(
                  child: Text('No lyrics loaded',
                      style: TextStyle(color: Colors.white70, fontSize: subFontSize)))
              : _KaraokeLyrics(
                  lyrics: state.lyrics,
                  position: state.playbackPosition,   // absolute position, no offset
                  glassColor: glassColor,
                  activeLyricIndex: state.activeLyricIndex,
                  style: state.animationStyle,
                  activeFontSize: lyricActiveFontSize,
                  inactiveFontSize: lyricInactiveFontSize,
                  lineFontSize: lyricLineFontSize,
                  blurRadius: blurRadius,
                ),
        ),
      ],
    );

    return GlassmorphicContainer(
      blurSigmaX: blurRadius,
      blurSigmaY: blurRadius,
      backgroundColor: glassColor.withOpacity(state.glassOpacity),
      borderColor: glassColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.all(paddingAll),
      child: card,
    );
  }
}

class _LyricHeader extends StatelessWidget {
  final LyricVideoState state;
  final SettingsRepository settingsRepo;
  final double avatarRadius;
  final double nameFontSize;
  final double subFontSize;
  final Color infoColor;

  const _LyricHeader({
    required this.state,
    required this.settingsRepo,
    this.avatarRadius = 28.0,
    this.nameFontSize = 16.0,
    this.subFontSize = 13.0,
    this.infoColor = const Color(0xFFF8BBD0),
  });

  @override
  Widget build(BuildContext context) {
    final partnerProfile = settingsRepo.partnerProfilePath;
    final partnerName = settingsRepo.partnerName.isNotEmpty
        ? settingsRepo.partnerName
        : 'Partner';
    final yourName =
        settingsRepo.yourName.isNotEmpty ? settingsRepo.yourName : 'You';
    final now = DateTime.now();
    int partnerAge = 0;
    if (settingsRepo.partnerBirthday != null) {
      partnerAge = now.year - settingsRepo.partnerBirthday!.year;
      final bday = settingsRepo.partnerBirthday!;
      if (now.month < bday.month ||
          (now.month == bday.month && now.day < bday.day)) partnerAge--;
    }
    final relationshipDays = settingsRepo.relationshipStart.daysBetween(now);
    final birthdayStr = settingsRepo.partnerBirthday != null
        ? _monthName(settingsRepo.partnerBirthday!.month) +
            ' ${settingsRepo.partnerBirthday!.day}'
        : '?';
    final genderLabel =
        (settingsRepo.partnerGender.toLowerCase() == 'female')
            ? 'Boyfriend'
            : 'Girlfriend';

    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: partnerProfile.isNotEmpty &&
                  File(partnerProfile).existsSync()
              ? FileImage(File(partnerProfile))
              : null,
          child: partnerProfile.isEmpty
              ? Icon(Icons.person, size: avatarRadius, color: Colors.white54)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(partnerName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('$partnerAge years  •  $relationshipDays days together',
                  style: TextStyle(color: infoColor, fontSize: subFontSize)),
              Text('Birthday: $birthdayStr  •  $genderLabel: $yourName',
                  style: TextStyle(color: infoColor, fontSize: subFontSize)),
            ],
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }
}

// ---- Karaoke lyrics engine (absolute sync, no startOffset) ----
class _KaraokeLyrics extends StatelessWidget {
  final List<LyricLine> lyrics;
  final Duration position;
  final Color glassColor;
  final int activeLyricIndex;
  final LyricAnimationStyle style;
  final double activeFontSize;
  final double inactiveFontSize;
  final double lineFontSize;
  final double blurRadius;

  const _KaraokeLyrics({
    required this.lyrics,
    required this.position,
    required this.glassColor,
    required this.activeLyricIndex,
    required this.style,
    this.activeFontSize = 26,
    this.inactiveFontSize = 20,
    this.lineFontSize = 24,
    this.blurRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    int idx = activeLyricIndex;
    if (idx < 0 || idx >= lyrics.length) {
      for (int i = 0; i < lyrics.length; i++) {
        if (position.inMilliseconds >= lyrics[i].milliseconds) {
          idx = i;
        } else {
          break;
        }
      }
    }
    if (idx < 0 || idx >= lyrics.length) return const SizedBox.shrink();

    final activeLine = lyrics[idx];
    final lineDurationMs = (idx < lyrics.length - 1)
        ? (lyrics[idx + 1].milliseconds - activeLine.milliseconds)
        : 3000;
    final elapsedInLine = position.inMilliseconds - activeLine.milliseconds;

    switch (style) {
      case LyricAnimationStyle.wordByWord:
        return _WordByWord(
          words: activeLine.text.split(RegExp(r'\s+')),
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          activeFontSize: activeFontSize,
          inactiveFontSize: inactiveFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.lineByLine:
        return _LineByLine(
          text: activeLine.text,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.fillUp:
        return _FillUp(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.fadeIn:
        return _FadeIn(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.bounce:
        return _Bounce(
          words: activeLine.text.split(RegExp(r'\s+')),
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          activeFontSize: activeFontSize,
          inactiveFontSize: inactiveFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.typewriter:
        return _Typewriter(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.wave:
        return _Wave(
          words: activeLine.text.split(RegExp(r'\s+')),
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          activeFontSize: activeFontSize,
          inactiveFontSize: inactiveFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.glitch:
        return _Glitch(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.drop:
        return _Drop(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.shine:
        return _Shine(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.zoomIn:
        return _ZoomIn(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.slideUp:
        return _SlideUp(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.rotate:
        return _Rotate(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
      case LyricAnimationStyle.heartbeat:
        return _Heartbeat(
          text: activeLine.text,
          elapsedInLine: elapsedInLine,
          lineDurationMs: lineDurationMs,
          glassColor: glassColor,
          fontSize: lineFontSize,
          blurRadius: blurRadius,
        );
    }
  }
}

// ---- Animation widgets (existing + 4 new) ----
class _WordByWord extends StatelessWidget {
  final List<String> words;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double activeFontSize;
  final double inactiveFontSize;
  final double blurRadius;

  const _WordByWord({
    required this.words,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.activeFontSize = 26,
    this.inactiveFontSize = 20,
    this.blurRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = _darkenColor(glassColor, 0.7);
    final inactiveColor = _lightenColor(glassColor, 0.5);
    final shadowColor = glassColor.withOpacity(0.5);
    final wordDurationMs = lineDurationMs / words.length;
    int activeWordIndex = (elapsedInLine / wordDurationMs)
        .floor()
        .clamp(0, words.length - 1);
    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(words.length, (i) {
        final isActive = i == activeWordIndex;
        final style = TextStyle(
          fontSize: isActive ? activeFontSize : inactiveFontSize,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? activeColor : inactiveColor,
          shadows: isActive ? [Shadow(blurRadius: blurRadius, color: shadowColor)] : null,
        );
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: style,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(words[i]),
          ),
        );
      }),
    );
  }
}

class _LineByLine extends StatelessWidget {
  final String text;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _LineByLine({
    required this.text,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Center(
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

class _FillUp extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _FillUp({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [activeColor, activeColor],
          stops: [0.0, progress],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: style.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _FadeIn({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = (elapsedInLine / 500).clamp(0.0, 1.0);
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Center(
      child: AnimatedOpacity(
        duration: Duration.zero,
        opacity: opacity,
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

class _Bounce extends StatelessWidget {
  final List<String> words;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double activeFontSize;
  final double inactiveFontSize;
  final double blurRadius;

  const _Bounce({
    required this.words,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.activeFontSize = 26,
    this.inactiveFontSize = 20,
    this.blurRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = _darkenColor(glassColor, 0.7);
    final inactiveColor = _lightenColor(glassColor, 0.5);
    final shadowColor = glassColor.withOpacity(0.5);
    final wordDurationMs = lineDurationMs / words.length;
    int activeWordIndex = (elapsedInLine / wordDurationMs)
        .floor()
        .clamp(0, words.length - 1);
    final progressInWord =
        (elapsedInLine - activeWordIndex * wordDurationMs) / wordDurationMs;
    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(words.length, (i) {
        final isActive = i == activeWordIndex;
        double scale = 1.0;
        if (isActive) {
          scale = 1.0 + 0.3 * (1.0 - (2 * progressInWord - 1).abs());
        }
        final style = TextStyle(
          fontSize: isActive ? activeFontSize : inactiveFontSize,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? activeColor : inactiveColor,
          shadows: isActive ? [Shadow(blurRadius: blurRadius, color: shadowColor)] : null,
        );
        return Transform.scale(
          scale: scale,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: style,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(words[i]),
            ),
          ),
        );
      }),
    );
  }
}

class _Typewriter extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _Typewriter({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    final charDurationMs = lineDurationMs / text.length;
    int visibleChars =
        (elapsedInLine / charDurationMs).floor().clamp(0, text.length);
    final displayText = text.substring(0, visibleChars);
    return Center(
      child: Text(displayText, textAlign: TextAlign.center, style: style),
    );
  }
}

class _Wave extends StatelessWidget {
  final List<String> words;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double activeFontSize;
  final double inactiveFontSize;
  final double blurRadius;

  const _Wave({
    required this.words,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.activeFontSize = 26,
    this.inactiveFontSize = 20,
    this.blurRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = _darkenColor(glassColor, 0.7);
    final inactiveColor = _lightenColor(glassColor, 0.5);
    final shadowColor = glassColor.withOpacity(0.5);
    final wordDurationMs = lineDurationMs / words.length;
    int activeWordIndex = (elapsedInLine / wordDurationMs)
        .floor()
        .clamp(0, words.length - 1);
    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(words.length, (i) {
        final isActive = i == activeWordIndex;
        final offsetY = isActive ? 4.0 * sin((elapsedInLine / 200) * pi) : 0.0;
        final style = TextStyle(
          fontSize: isActive ? activeFontSize : inactiveFontSize,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? activeColor : inactiveColor,
          shadows: isActive ? [Shadow(blurRadius: blurRadius, color: shadowColor)] : null,
        );
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: style,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(words[i]),
            ),
          ),
        );
      }),
    );
  }
}

class _Glitch extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _Glitch({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final jitter = progress < 1.0 && (elapsedInLine % 120 < 30) ? 3.0 : 0.0;
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    final splitColor = progress < 1.0 && (elapsedInLine % 200 < 60)
        ? glassColor
        : Colors.white;
    return Stack(
      children: [
        if (jitter > 0)
          Positioned(
            left: jitter,
            child: Opacity(
              opacity: 0.5,
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: style.copyWith(color: splitColor)),
            ),
          ),
        Positioned(
          right: jitter,
          child: Text(text,
              textAlign: TextAlign.center,
              style: style.copyWith(
                  color: progress < 1.0 ? style.color : splitColor)),
        ),
      ],
    );
  }
}

class _Drop extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _Drop({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final dropOffset = (1 - progress) * 40;
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Transform.translate(
      offset: Offset(0, dropOffset),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: progress.clamp(0.0, 1.0),
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

class _Shine extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _Shine({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final shineCenter = progress;
    const highlightWidth = 0.3;
    final start = (shineCenter - highlightWidth).clamp(0.0, 1.0);
    final end = (shineCenter + highlightWidth).clamp(0.0, 1.0);
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return ShaderMask(
      shaderCallback: (bounds) {
        return ui.Gradient.linear(
          Offset.zero,
          Offset(bounds.width, 0),
          [activeColor, Colors.white],
          [start, end],
        );
      },
      blendMode: BlendMode.srcATop,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

// ---- New animation styles ----
class _ZoomIn extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _ZoomIn({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final scale = 0.5 + progress * 0.5;
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Center(
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

class _SlideUp extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _SlideUp({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final offsetY = 40.0 * (1 - progress);
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Center(
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

class _Rotate extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _Rotate({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final angle = 0.1 * (1 - progress) * pi;
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Center(
      child: Transform.rotate(
        angle: angle,
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}

class _Heartbeat extends StatelessWidget {
  final String text;
  final int elapsedInLine;
  final int lineDurationMs;
  final Color glassColor;
  final double fontSize;
  final double blurRadius;

  const _Heartbeat({
    required this.text,
    required this.elapsedInLine,
    required this.lineDurationMs,
    required this.glassColor,
    this.fontSize = 24,
    this.blurRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedInLine / lineDurationMs).clamp(0.0, 1.0);
    final scale = 1.0 + 0.1 * (1 - 2 * (progress - 0.5).abs());
    final activeColor = _darkenColor(glassColor, 0.7);
    final shadowColor = glassColor.withOpacity(0.5);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: activeColor,
      shadows: [Shadow(blurRadius: blurRadius, color: shadowColor)],
    );
    return Center(
      child: Transform.scale(
        scale: scale,
        child: Text(text, textAlign: TextAlign.center, style: style),
      ),
    );
  }
}