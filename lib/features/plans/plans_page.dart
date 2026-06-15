import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared_widgets/empty_state_widget.dart';
import '../../shared_widgets/glassmorphic_card.dart';
import '../../shared_widgets/loading_indicator.dart';
import 'bloc/plans_cubit.dart';
import 'bloc/plans_state.dart';
import 'widgets/calendar_widget.dart';
import 'widgets/reminder_tile.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlansBody();
  }
}

class _PlansBody extends StatefulWidget {
  const _PlansBody();

  @override
  State<_PlansBody> createState() => _PlansBodyState();
}

class _PlansBodyState extends State<_PlansBody> {
  bool _autoEventsGenerated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAutoEvents();
    });
  }

  /// Generates auto‑events for birthdays, monthly & yearly anniversaries.
  /// Uses real names from Settings and avoids duplicates by checking both
  /// the title AND the specific month/year.
  Future<void> _generateAutoEvents() async {
    if (_autoEventsGenerated) return;
    _autoEventsGenerated = true;

    final cubit = context.read<PlansCubit>();
    final settingsRepo = context.read<SettingsRepository>();

    // Load all existing events from DB
    await cubit.loadAllEvents();
    final existingEvents = cubit.state.events;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Helper to check if an event with the same title & date (ignoring time) already exists
    bool eventExists(String title, DateTime date) {
      return existingEvents.any((e) =>
          e.title == title &&
          e.eventDate.year == date.year &&
          e.eventDate.month == date.month &&
          e.eventDate.day == date.day);
    }

    // 1. Monthly Anniversary (next upcoming occurrence)
    final relationshipStart = settingsRepo.relationshipStart;
    final startDay = relationshipStart.day;
    // Compute the next monthly anniversary that is ≥ today
    DateTime nextMonthly = DateTime(now.year, now.month, startDay);
    if (nextMonthly.isBefore(today)) {
      // Move to next month
      nextMonthly = DateTime(now.year, now.month + 1, startDay);
    }
    if (!eventExists('Monthly Anniversary', nextMonthly)) {
      await cubit.addEvent(
        title: 'Monthly Anniversary',
        eventDate: nextMonthly,
      );
    }

    // 2. Yearly Anniversary (next upcoming)
    final yearsSince = now.year - relationshipStart.year;
    DateTime nextYearly = DateTime(
        relationshipStart.year + yearsSince,
        relationshipStart.month,
        relationshipStart.day);
    if (nextYearly.isBefore(today)) {
      nextYearly = DateTime(
          relationshipStart.year + yearsSince + 1,
          relationshipStart.month,
          relationshipStart.day);
    }
    if (!eventExists('Yearly Anniversary', nextYearly)) {
      await cubit.addEvent(
        title: 'Yearly Anniversary',
        eventDate: nextYearly,
        reminderTime: DateTime(nextYearly.year, nextYearly.month,
            nextYearly.day, 9, 0),
      );
    }

    // 3 & 4. Birthdays (using real names)
    final yourName = settingsRepo.yourName.isNotEmpty
        ? settingsRepo.yourName
        : 'Your';
    final partnerName = settingsRepo.partnerName.isNotEmpty
        ? settingsRepo.partnerName
        : 'Partner';

    Future<void> addBirthdayIfNeeded(
        DateTime? birthday, String name) async {
      if (birthday == null) return;
      final title = '$name\'s Birthday';
      // Find next upcoming birthday
      DateTime nextBirthday = DateTime(now.year, birthday.month, birthday.day);
      if (nextBirthday.isBefore(today)) {
        nextBirthday = DateTime(now.year + 1, birthday.month, birthday.day);
      }
      if (!eventExists(title, nextBirthday)) {
        await cubit.addEvent(
          title: title,
          eventDate: nextBirthday,
        );
      }
    }

    await addBirthdayIfNeeded(settingsRepo.yourBirthday, yourName);
    await addBirthdayIfNeeded(settingsRepo.partnerBirthday, partnerName);

    // Final reload so the UI shows everything
    await cubit.loadAllEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.plansTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CalendarWidget(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _showEventForm(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildUpcomingEventList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventList() {
    return BlocBuilder<PlansCubit, PlansState>(
      builder: (context, state) {
        if (state.isLoading && state.events.isEmpty) {
          return const LoadingIndicator(message: Strings.loading);
        }
        if (state.errorMessage != null && state.events.isEmpty) {
          return EmptyStateWidget(
            message: state.errorMessage!,
            icon: Icons.error_outline,
            onAction: () => context.read<PlansCubit>().loadAllEvents(),
            actionLabel: Strings.retry,
          );
        }

        final now = DateTime.now();
        final upcoming = state.events
            .where((e) =>
                e.eventDate
                    .isAfter(now.subtract(const Duration(days: 1))))
            .toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

        if (upcoming.isEmpty) {
          return EmptyStateWidget(
            message: 'No upcoming events',
            icon: Icons.event_busy_outlined,
            onAction: () => _showEventForm(context),
            actionLabel: Strings.plansAddEvent,
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: upcoming.length,
          itemBuilder: (ctx, index) {
            final event = upcoming[index];
            return _EventCard(
              event: event,
              onEdit: () => _showEventForm(context, event: event),
              onDelete: () => _confirmDelete(context, event.id),
            );
          },
        );
      },
    );
  }

  void _showEventForm(BuildContext context, {CalendarEventData? event}) {
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    DateTime eventDate =
        event?.eventDate ?? context.read<PlansCubit>().state.selectedDate;
    TimeOfDay? eventTime;
    DateTime? reminderTime = event?.reminderTime;

    if (event?.eventTime != null) {
      final et = event!.eventTime!;
      eventTime = TimeOfDay(hour: et.hour, minute: et.minute);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            event == null ? Strings.plansAddEvent : Strings.plansEditEvent,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: Strings.plansEventTitle,
                    hintText: 'Enter event title…',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: eventDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => eventDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: Text(eventTime == null
                      ? 'All day'
                      : '${eventTime!.hour.toString().padLeft(2, '0')}:${eventTime!.minute.toString().padLeft(2, '0')}'),
                  leading: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: eventTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setDialogState(() => eventTime = time);
                    }
                  },
                ),
                ReminderTile(
                  reminderTime: reminderTime,
                  onTimeChanged: (newReminder) {
                    setDialogState(() => reminderTime = newReminder);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(Strings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final cubit = context.read<PlansCubit>();
                final combinedDate = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                  eventTime?.hour ?? 0,
                  eventTime?.minute ?? 0,
                );

                if (event == null) {
                  cubit.addEvent(
                    title: title,
                    eventDate: combinedDate,
                    eventTime: eventTime != null ? combinedDate : null,
                    reminderTime: reminderTime,
                  );
                } else {
                  cubit.updateEvent(
                    id: event.id,
                    title: title,
                    eventDate: combinedDate,
                    eventTime: eventTime != null ? combinedDate : null,
                    reminderTime: reminderTime,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text(Strings.save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Remove this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<PlansCubit>().deleteEvent(id);
              Navigator.pop(ctx);
            },
            child: const Text(Strings.delete,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarEventData event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = event.eventTime != null
        ? '${event.eventTime!.hour.toString().padLeft(2, '0')}:${event.eventTime!.minute.toString().padLeft(2, '0')}'
        : 'All day';
    final hasReminder = event.reminderTime != null;
    final formattedDate =
        '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(formattedDate, style: theme.textTheme.bodySmall),
                      if (event.eventTime != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.access_time,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(timeStr, style: theme.textTheme.bodySmall),
                      ],
                      if (hasReminder) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.alarm,
                            size: 14, color: theme.colorScheme.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: theme.colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}