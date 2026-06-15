// lib/features/plans/widgets/reminder_tile.dart

import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';

/// A compact tile used inside the calendar event form to display an optional
/// reminder time.  Tapping it opens a time picker.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminderTime,
    required this.onTimeChanged,
  });

  final DateTime? reminderTime;
  final ValueChanged<DateTime?> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = reminderTime == null
        ? 'No reminder set'
        : 'Reminder at ${reminderTime!.hour.toString().padLeft(2, '0')}:${reminderTime!.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: Icon(
        reminderTime == null ? Icons.alarm_off_outlined : Icons.alarm_on_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(label),
      trailing: IconButton(
        icon: Icon(
          reminderTime == null ? Icons.add : Icons.clear,
          size: 20,
        ),
        onPressed: () => _handleTap(context),
      ),
      onTap: () => _handleTap(context),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (reminderTime != null) {
      onTimeChanged(null);
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null && context.mounted) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      onTimeChanged(dt);
    }
  }
}