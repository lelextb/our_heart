import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/glassmorphism.dart';

/// A custom PIN input widget with a glassmorphic on‑screen numpad.
///
/// The title, pin dots, and error message are displayed inside a
/// GlassmorphicContainer.  The numpad is placed **outside** the
/// container, directly below it, with its own glassmorphic styling.
class PinInputWidget extends StatefulWidget {
  const PinInputWidget({
    super.key,
    required this.onPinComplete,
    required this.title,
    this.errorMessage,
    this.enabled = true,
  });

  final ValueChanged<String> onPinComplete;
  final String title;
  final String? errorMessage;
  final bool enabled;

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<String> _digits = []; // max 4

  void _addDigit(String digit) {
    if (!widget.enabled) return;
    if (_digits.length >= 4) return;
    setState(() {
      _digits.add(digit);
    });
  }

  void _backspace() {
    if (!widget.enabled) return;
    if (_digits.isEmpty) return;
    setState(() {
      _digits.removeLast();
    });
  }

  void _enter() {
    if (!widget.enabled) return;
    if (_digits.length == 4) {
      widget.onPinComplete(_digits.join());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Glassmorphic card: title + dots + error ---
        GlassmorphicContainer(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Pin dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _digits.length;
                  return Container(
                    width: 48,
                    height: 54,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: filled
                          ? AppColors.primary.withOpacity(0.15)
                          : (isDark
                                  ? AppColors.cardDark
                                  : AppColors.cardLight)
                              .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: filled
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.glassBorderDark
                                : AppColors.glassBorderLight),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: filled
                          ? Text(
                              _digits[index],
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                        .withOpacity(0.4)
                                    : AppColors.textLightSecondary
                                        .withOpacity(0.4),
                              ),
                            ),
                    ),
                  );
                }),
              ),
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- Numpad OUTSIDE the glass container ---
        _Numpad(
          isDark: isDark,
          enabled: widget.enabled,
          onDigit: _addDigit,
          onBackspace: _backspace,
          onEnter: _enter,
        ),
      ],
    );
  }
}

/// Glassmorphic 3×4 grid: 1‑9, 0, backspace, enter.
class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.isDark,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onEnter,
  });

  final bool isDark;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    // Wrap the entire numpad in its own glassmorphic container
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(8.0),
      borderRadius: BorderRadius.circular(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['⌫', '0', '✓'], // backspace, 0, enter
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((label) {
                if (label == '⌫') {
                  return _NumButton(
                    isDark: isDark,
                    enabled: enabled,
                    onTap: onBackspace,
                    child: Icon(Icons.backspace_outlined,
                        size: 26,
                        color: enabled
                            ? (isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary)
                            : Colors.grey),
                  );
                }
                if (label == '✓') {
                  return _NumButton(
                    isDark: isDark,
                    enabled: enabled,
                    onTap: onEnter,
                    child: Icon(Icons.check,
                        size: 26,
                        color: enabled ? AppColors.primary : Colors.grey),
                  );
                }
                return _NumButton(
                  isDark: isDark,
                  enabled: enabled,
                  onTap: () => onDigit(label),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? (isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textLightPrimary)
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

/// A single glassmorphic key on the numpad.
class _NumButton extends StatelessWidget {
  const _NumButton({
    required this.isDark,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.2),
          child: Container(
            width: 68,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.glassDark.withOpacity(0.7)
                  : AppColors.glassLight.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.glassBorderDark.withOpacity(0.5)
                    : AppColors.glassBorderLight.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}