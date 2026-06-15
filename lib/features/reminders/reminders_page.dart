import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../core/theme/colors.dart';
import '../../shared_widgets/empty_state_widget.dart';
import '../../shared_widgets/loading_indicator.dart';
import 'bloc/reminders_cubit.dart';
import 'bloc/reminders_state.dart';
import 'widgets/reminder_card.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) => const _RemindersBody();
}

class _RemindersBody extends StatefulWidget {
  const _RemindersBody();

  @override
  State<_RemindersBody> createState() => _RemindersBodyState();
}

class _RemindersBodyState extends State<_RemindersBody> {
  @override
  void initState() {
    super.initState();
    context.read<RemindersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.remindersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        if (state.isLoading && state.reminders.isEmpty) {
          return const LoadingIndicator(message: Strings.loading);
        }
        if (state.errorMessage != null && state.reminders.isEmpty) {
          return EmptyStateWidget(
            message: state.errorMessage!,
            icon: Icons.error_outline,
            onAction: () => context.read<RemindersCubit>().load(),
            actionLabel: Strings.retry,
          );
        }
        if (state.reminders.isEmpty) {
          return EmptyStateWidget(
            message: Strings.remindersNoUpcoming,
            icon: Icons.alarm_off_outlined,
            onAction: () => _showEditDialog(context),
            actionLabel: Strings.remindersAdd,
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: state.reminders.length,
              itemBuilder: (ctx, index) {
                final reminder = state.reminders[index];
                final isSelected = state.selectedIds.contains(reminder.id);
                return ReminderCard(
                  description: reminder.description,
                  reminderTime: reminder.reminderTime,
                  isSelected: isSelected,
                  onTap: () {
                    if (state.selectedIds.isNotEmpty) {
                      context.read<RemindersCubit>().toggleSelection(reminder.id);
                    } else {
                      _showEditDialog(context, reminder: reminder);
                    }
                  },
                  onLongPress: () {
                    context.read<RemindersCubit>().toggleSelection(reminder.id);
                  },
                  onDelete: () => _confirmDelete(context, reminder.id),
                );
              },
            ),
            if (state.selectedIds.isNotEmpty)
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: () => _confirmBulkDelete(context),
                  child: const Icon(Icons.delete),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, {ReminderData? reminder}) {
    final descCtrl =
        TextEditingController(text: reminder?.description ?? '');
    DateTime? selectedTime = reminder?.reminderTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(reminder == null ? Strings.remindersAdd : 'Edit Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(hintText: Strings.remindersDescription),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(selectedTime == null
                    ? 'Set time'
                    : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime != null
                        ? TimeOfDay(
                            hour: selectedTime!.hour,
                            minute: selectedTime!.minute)
                        : TimeOfDay.now(),
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedTime = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(Strings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final desc = descCtrl.text.trim();
                if (desc.isEmpty || selectedTime == null) return;
                final cubit = context.read<RemindersCubit>();
                if (reminder == null) {
                  cubit.add(
                    description: desc,
                    reminderTime: selectedTime!,
                  );
                } else {
                  cubit.update(
                    id: reminder.id,
                    description: desc,
                    reminderTime: selectedTime,
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
        title: const Text('Delete Reminder'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<RemindersCubit>().delete(id);
              Navigator.pop(ctx);
            },
            child: const Text(Strings.delete,
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context) {
    final count = context.read<RemindersCubit>().state.selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminders'),
        content: Text('Delete $count reminder(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<RemindersCubit>().deleteSelected();
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