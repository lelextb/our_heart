// lib/features/plans/widgets/calendar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../shared_widgets/glassmorphic_card.dart';
import '../bloc/plans_cubit.dart';
import '../bloc/plans_state.dart';

/// A Glassmorphism‑wrapped calendar that displays dots on dates that have
/// events.  Tapping a date selects it and loads the events for that day.
///
/// The calendar supports month/week/two‑week views and responds to theme
/// changes.
class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansCubit, PlansState>(
      builder: (context, state) {
        return GlassmorphicCard(
          padding: const EdgeInsets.all(12.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: state.selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              context.read<PlansCubit>().selectDate(selectedDay);
            },
            eventLoader: (day) {
              // Return list of events for this day; we use a dummy list to
              // trigger dots – the actual list isn't used except to paint markers.
              final events = state.events
                  .where((e) => isSameDay(e.eventDate, day))
                  .toList();
              return events.isEmpty ? [] : [events.first]; // marker indicator
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
              weekendStyle: (Theme.of(context).textTheme.labelMedium ?? const TextStyle()).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }
}