// lib/features/home/widgets/heart_animation.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/glassmorphism.dart';
import '../../../core/utils/date_utils.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';

/// A large, glassmorphic heart that fills from the bottom.  Profile
/// pictures are displayed large inside the heart, with a glassmorphic
/// “&” symbol between them and glassmorphic name cards underneath.
class HeartFillingAnimation extends StatefulWidget {
  const HeartFillingAnimation({
    super.key,
    required this.yourName,
    required this.partnerName,
    required this.yourProfilePath,
    required this.partnerProfilePath,
  });

  final String yourName;
  final String partnerName;
  final String yourProfilePath;
  final String partnerProfilePath;

  @override
  State<HeartFillingAnimation> createState() => _HeartFillingAnimationState();
}

class _HeartFillingAnimationState extends State<HeartFillingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fillAnimation;
  Timer? _updateTimer;
  double _targetFill = 0.0;
  double _currentFill = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _fillAnimation.addListener(() {
      setState(() {
        _currentFill = _fillAnimation.value;
      });
    });
    _recalculateFill();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _recalculateFill();
    });
  }

  void _recalculateFill() {
    final cubit = context.read<HomeCubit>();
    final start = cubit.state.relationshipStart;
    if (start == DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)) {
      _targetFill = 0.0;
    } else {
      final now = DateTime.now();
      final daysTogether = start.daysBetween(now);
      const maxDays = 3650;
      _targetFill = (daysTogether / maxDays).clamp(0.0, 1.0);
    }
    _controller.animateTo(_targetFill);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ---- Neon blurred background behind the heart ----
              Positioned.fill(
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF6B81),
                            Color(0xFFFF4081),
                            Color(0xFFFF1744),
                            Color(0xFFFFD700),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ---- Frosted glass heart container ----
              Positioned.fill(
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ---- Filling progress from the bottom ----
              Positioned.fill(
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: _currentFill,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B81).withOpacity(0.6),
                              const Color(0xFFFF1744).withOpacity(0.8),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ---- Content: big avatars, glassmorphic “&”, glassmorphic names ----
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.08,
                    vertical: h * 0.08,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatars row with glassmorphic “&” in the centre
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildAvatar(widget.yourProfilePath, widget.yourName,
                              w * 0.22),
                          const SizedBox(width: 8),
                          // Glassmorphic ampersand
                          GlassmorphicContainer(
                            width: w * 0.12,
                            height: w * 0.12,
                            borderRadius:
                                BorderRadius.circular(w * 0.06), // circle
                            padding: EdgeInsets.zero,
                            child: const Center(
                              child: Text(
                                '&',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildAvatar(widget.partnerProfilePath,
                              widget.partnerName, w * 0.22),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Names – each in its own glassmorphic pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: GlassmorphicContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              borderRadius: BorderRadius.circular(20),
                              child: Text(
                                widget.yourName.isEmpty
                                    ? 'You'
                                    : widget.yourName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: GlassmorphicContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              borderRadius: BorderRadius.circular(20),
                              child: Text(
                                widget.partnerName.isEmpty
                                    ? 'Partner'
                                    : widget.partnerName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String path, String fallbackName, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        image: path.isNotEmpty && File(path).existsSync()
            ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)
            : null,
      ),
      child: path.isEmpty || !File(path).existsSync()
          ? Icon(Icons.person,
              size: size * 0.6, color: Colors.white.withOpacity(0.6))
          : null,
    );
  }
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.95);
    path.cubicTo(
      w * 0.02, h * 0.55,
      w * 0.0, h * 0.15,
      w * 0.5, h * 0.25,
    );
    path.cubicTo(
      w * 1.0, h * 0.15,
      w * 0.98, h * 0.55,
      w * 0.5, h * 0.95,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HeartClipper oldClipper) => false;
}