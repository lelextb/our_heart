// lib/features/home/home_page.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../core/constants/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/image_utils.dart';
import '../../shared_widgets/floating_dock.dart';
import '../../shared_widgets/top_bar_buttons.dart';
import '../gallery/bloc/gallery_cubit.dart';
import '../settings/bloc/settings_cubit.dart';
import 'bloc/home_cubit.dart';
import 'bloc/home_state.dart';
import 'widgets/affirmations_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomeCubit _homeCubit;
  int _currentDockIndex = 0;

  final ScrollController _scrollController = ScrollController();
  bool _topBarVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeCubit = context.read<HomeCubit>();
    _startCounterRefresh();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _counterTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      if (_topBarVisible) setState(() => _topBarVisible = false);
    } else if (direction == ScrollDirection.forward) {
      if (!_topBarVisible) setState(() => _topBarVisible = true);
    }
  }

  Timer? _counterTimer;
  void _startCounterRefresh() {
    _counterTimer?.cancel();
    _counterTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _homeCubit.refreshRelationship();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _counterTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _homeCubit.refreshRelationship();
      _startCounterRefresh();
    }
  }

  // Dock indices: 0=Home, 1=Info, 2=Plans, 3=Gallery
  void _onDockDestinationSelected(int index) async {
    if (index == _currentDockIndex) return;
    setState(() => _currentDockIndex = index);

    switch (index) {
      case 0:
        break; // Home
      case 1:
        await Navigator.of(context).pushNamed('/info');
        break;
      case 2:
        await Navigator.of(context).pushNamed('/plans');
        break;
      case 3:
        await Navigator.of(context).pushNamed('/lyric_video');
        break;
    }
    if (mounted) {
      setState(() => _currentDockIndex = 0);
    }
  }

  Future<void> _onFabPressed() async {
    final cubit = context.read<GalleryCubit>();
    // Ensure categories are loaded
    if (cubit.state.categories.isEmpty) {
      await cubit.loadCategories();
    }
    // Find or create a default "General" category
    int? generalId;
    try {
      generalId =
          cubit.state.categories.firstWhere((c) => c.name == 'General').id;
    } catch (_) {
      // Not found – create it
      await cubit.createCategory(name: 'General', description: 'Default album');
      await cubit.loadCategories();
      generalId =
          cubit.state.categories.firstWhere((c) => c.name == 'General').id;
    }
    final success = await cubit.addPhotoToCategory(generalId);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo added!')),
      );
    }
  }

  Future<void> _pickProfilePicture({required bool isYour}) async {
    final prefix = isYour ? 'profile_your' : 'profile_partner';
    final path = await ImageUtils.pickAndCropImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      cropStyle: CropStyle.circle,
      prefix: prefix,
    );
    if (path == null) return;
    if (mounted) {
      context.read<SettingsCubit>().updateProfilePicture(
            isYour ? 'your' : 'partner',
            customPath: path,
          );
      _homeCubit.refreshRelationship();
    }
  }

  void _onLoveLanguagesReordered(List<String> newOrder) {
    final cubit = context.read<SettingsCubit>();
    cubit.updateLoveLanguages(newOrder);
    _homeCubit.refreshRelationship();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final loveLanguages = state.loveLanguages ?? const [];
        final pronounce = state.pronounceText;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 48, 0, 100),
                  child: Column(
                    children: [
                      _ProfileSection(
                        yourName: state.yourName,
                        partnerName: state.partnerName,
                        yourProfilePath: state.yourProfilePath,
                        partnerProfilePath: state.partnerProfilePath,
                        onYourPicTap: () => _pickProfilePicture(isYour: true),
                        onPartnerPicTap: () =>
                            _pickProfilePicture(isYour: false),
                      ),
                      const SizedBox(height: 16),
                      if (state.yourBirthday != null ||
                          state.partnerBirthday != null) ...[
                        _BirthdaySection(
                          yourBirthday: state.yourBirthday,
                          partnerBirthday: state.partnerBirthday,
                          yourName: state.yourName,
                          partnerName: state.partnerName,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _RelationshipCounter(
                            relationshipStart: state.relationshipStart),
                      ),
                      const SizedBox(height: 16),
                      if (loveLanguages.isNotEmpty) ...[
                        _LoveLanguagesSection(
                          loveLanguages: loveLanguages,
                          partnerName: state.partnerName,
                          onReorder: _onLoveLanguagesReordered,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:
                            AffirmationsCard(affirmations: state.affirmations),
                      ),
                      const SizedBox(height: 16),
                      if (pronounce != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _PronounceCard(text: pronounce),
                        ),
                    ],
                  ),
                ),
                // Top bar – hides on scroll down, reappears on scroll up
                if (_topBarVisible)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: TopBarButtons(
                      onSettingsTap: () =>
                          Navigator.pushNamed(context, '/settings'),
                      onRemindersTap: () =>
                          Navigator.pushNamed(context, '/reminders'),
                      onLettersTap: () =>
                          Navigator.pushNamed(context, '/letters'),
                      onGalleryTap: () =>
                          Navigator.pushNamed(context, '/gallery'),
                    ),
                  ),
              ],
            ),
          ),
          // Floating dock always visible
          bottomNavigationBar: FloatingDock(
            currentIndex: _currentDockIndex,
            onDestinationSelected: _onDockDestinationSelected,
            onFabPressed: _onFabPressed,
          ),
        );
      },
    );
  }
}

// =====================================================================
// Profile section
// =====================================================================
class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.yourName,
    required this.partnerName,
    required this.yourProfilePath,
    required this.partnerProfilePath,
    required this.onYourPicTap,
    required this.onPartnerPicTap,
  });

  final String yourName;
  final String partnerName;
  final String yourProfilePath;
  final String partnerProfilePath;
  final VoidCallback onYourPicTap;
  final VoidCallback onPartnerPicTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = (screenWidth * 0.28).clamp(72.0, 120.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    final loveWords = ['LOVES', 'ADORES', 'CHERISHES', 'HOLDS', 'KEEPS'];
    final randomWord = loveWords[Random(DateTime.now().millisecondsSinceEpoch)
        .nextInt(loveWords.length)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassmorphicContainer(
        backgroundColor: glassBg,
        borderColor: AppColors.primary.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onYourPicTap,
                  child: _ProfileAvatar(
                    profilePath: yourProfilePath,
                    size: avatarSize,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GlassmorphicContainer(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(24),
                    padding: EdgeInsets.zero,
                    backgroundColor: AppColors.primary.withOpacity(0.25),
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
                ),
                GestureDetector(
                  onTap: onPartnerPicTap,
                  child: _ProfileAvatar(
                    profilePath: partnerProfilePath,
                    size: avatarSize,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            GlassmorphicContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              backgroundColor: AppColors.primaryVariant.withOpacity(0.35),
              borderColor: AppColors.primaryVariant.withOpacity(0.6),
              child: Text(
                randomWord,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GlassmorphicContainer(
                    backgroundColor: AppColors.primary.withOpacity(0.18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    borderRadius: BorderRadius.circular(20),
                    child: Text(
                      yourName.isEmpty ? 'You' : yourName,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: GlassmorphicContainer(
                    backgroundColor: AppColors.primary.withOpacity(0.18),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    borderRadius: BorderRadius.circular(20),
                    child: Text(
                      partnerName.isEmpty ? 'Partner' : partnerName,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
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
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profilePath, required this.size});
  final String profilePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.primary.withOpacity(0.8), width: 2),
        image: profilePath.isNotEmpty && File(profilePath).existsSync()
            ? DecorationImage(
                image: FileImage(File(profilePath)), fit: BoxFit.cover)
            : null,
      ),
      child: profilePath.isEmpty || !File(profilePath).existsSync()
          ? Icon(Icons.person,
              size: size * 0.6, color: Colors.white.withOpacity(0.6))
          : null,
    );
  }
}

// =====================================================================
// Birthday section
// =====================================================================
class _BirthdaySection extends StatelessWidget {
  const _BirthdaySection({
    required this.yourBirthday,
    required this.partnerBirthday,
    required this.yourName,
    required this.partnerName,
  });

  final DateTime? yourBirthday;
  final DateTime? partnerBirthday;
  final String yourName;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassmorphicContainer(
        backgroundColor: glassBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (yourBirthday != null)
              _BirthdayChip(
                label: '${yourName.isNotEmpty ? yourName : 'You'}',
                date: yourBirthday!,
              ),
            if (yourBirthday != null && partnerBirthday != null)
              Container(
                width: 1,
                height: 24,
                color: AppColors.primary.withOpacity(0.3),
              ),
            if (partnerBirthday != null)
              _BirthdayChip(
                label: '${partnerName.isNotEmpty ? partnerName : 'Partner'}',
                date: partnerBirthday!,
              ),
          ],
        ),
      ),
    );
  }
}

class _BirthdayChip extends StatelessWidget {
  const _BirthdayChip({required this.label, required this.date});
  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = months[date.month];
    final day = date.day;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cake, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          '$label: $monthName $day',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// =====================================================================
// Relationship counter
// =====================================================================
class _RelationshipCounter extends StatelessWidget {
  const _RelationshipCounter({required this.relationshipStart});
  final DateTime relationshipStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    if (relationshipStart ==
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)) {
      return GlassmorphicContainer(
        backgroundColor: glassBg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'Set your relationship start date in Settings',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final now = DateTime.now();
    final days = relationshipStart.daysBetween(now);
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final remainingDays = (days % 365) % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years year${years == 1 ? '' : 's'}');
    if (months > 0) parts.add('$months month${months == 1 ? '' : 's'}');
    if (remainingDays > 0 || parts.isEmpty) {
      parts.add('$remainingDays day${remainingDays == 1 ? '' : 's'}');
    }

    return GlassmorphicContainer(
      backgroundColor: glassBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '${Strings.homeRelationshipLabel} ${parts.join(', ')}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Love languages horizontally scrollable & reorderable by long-press
// =====================================================================
class _LoveLanguagesSection extends StatelessWidget {
  const _LoveLanguagesSection({
    required this.loveLanguages,
    required this.partnerName,
    required this.onReorder,
  });

  final List<String> loveLanguages;
  final String partnerName;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${partnerName.isNotEmpty ? partnerName : 'Partner'}\'s Love Languages',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: loveLanguages.length,
            onReorder: (oldIndex, newIndex) {
              final reordered = List<String>.from(loveLanguages);
              final item = reordered.removeAt(oldIndex);
              reordered.insert(
                  newIndex > oldIndex ? newIndex - 1 : newIndex, item);
              onReorder(reordered);
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double scale =
                      ui.lerpDouble(1.0, 1.08, animation.value)!;
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 4,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            itemBuilder: (ctx, index) {
              return Padding(
                key: ValueKey(loveLanguages[index]),
                padding: const EdgeInsets.only(right: 8),
                child: GlassmorphicContainer(
                  backgroundColor: glassBg,
                  borderColor: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    loveLanguages[index],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textLightPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// Pronounce card
// =====================================================================
class _PronounceCard extends StatelessWidget {
  const _PronounceCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    return GlassmorphicContainer(
      backgroundColor: glassBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}