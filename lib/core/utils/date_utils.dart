// lib/core/utils/date_utils.dart

/// Extension providing common date‑difference calculations used throughout the
/// application (relationship counter, upcoming reminder checks, etc.).
extension DateUtilsExtension on DateTime {
  /// Returns the number of full calendar days between [this] and [other].
  ///
  /// Both dates are normalised to **local** start‑of‑day before comparison,
  /// matching the Kotlin [DateUtils.daysSince] implementation.
  /// The result is always non‑negative.
  int daysBetween(DateTime other) {
    final a = DateTime(year, month, day);
    final b = DateTime(other.year, other.month, other.day);
    return (b.difference(a).inHours / 24).round().abs();
  }

  /// Whether this date is in the future (including today).
  bool get isFutureOrToday {
    final now = DateTime.now();
    return isAfter(now) || isAtSameMomentAs(DateTime(now.year, now.month, now.day));
  }

  /// Whether this date is strictly before today.
  bool get isPast => !isFutureOrToday;

  /// Normalised start‑of‑day DateTime in local time.
  DateTime get startOfDay => DateTime(year, month, day);
}

/// Static helpers.
class AppDateUtils {
  AppDateUtils._();

  /// Formats a [Duration] into a human‑friendly string like "2 years, 3 months, 5 days".
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    final remainingDays = (days % 365) % 30;

    final parts = <String>[];
    if (years > 0) parts.add('$years year${years == 1 ? '' : 's'}');
    if (months > 0) parts.add('$months month${months == 1 ? '' : 's'}');
    if (remainingDays > 0 || parts.isEmpty) {
      parts.add('$remainingDays day${remainingDays == 1 ? '' : 's'}');
    }
    return parts.join(', ');
  }
}