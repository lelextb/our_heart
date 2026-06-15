import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/glassmorphism.dart';

/// A custom floating bottom navigation dock with a Glassmorphism background.
///
/// Displays 4 navigation items (Home, Info, Plans, Lyric Video) plus a central
/// FAB that adds a new photo.  The dock always floats above the page content,
/// and its blur effect adapts to light/dark mode.
class FloatingDock extends StatefulWidget {
  const FloatingDock({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onFabPressed,
  });

  /// Index of the currently selected destination (0‑3).
  final int currentIndex;

  /// Called when a navigation destination is tapped.
  final ValueChanged<int> onDestinationSelected;

  /// Called when the central FAB is pressed.
  final VoidCallback onFabPressed;

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabController;
  late final Animation<double> _fabScaleAnimation;

  static const _destinations = <_DockItem>[
    _DockItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _DockItem(icon: Icons.info_outline, activeIcon: Icons.info, label: 'Info'),
    _DockItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Plans'),
    _DockItem(icon: Icons.music_note_outlined, activeIcon: Icons.music_note, label: 'Music'),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onFabTap() {
    _fabController.forward().then((_) => _fabController.reverse());
    widget.onFabPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphicContainer(
        blurSigmaX: 12,
        blurSigmaY: 12,
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        backgroundColor: isDark ? AppColors.glassDark : AppColors.glassLight,
        borderColor: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < 2; i++) _buildNavItem(i, isDark),
              // Central FAB
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ScaleTransition(
                  scale: _fabScaleAnimation,
                  child: FloatingActionButton(
                    mini: false,
                    onPressed: _onFabTap,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.add_a_photo_outlined,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
              for (int i = 2; i < _destinations.length; i++)
                _buildNavItem(i, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final selected = widget.currentIndex == index;
    final item = _destinations[index];
    final color = selected
        ? AppColors.primary
        : isDark
            ? AppColors.textDarkSecondary
            : AppColors.textLightSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => widget.onDestinationSelected(index),
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.primary.withOpacity(0.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}