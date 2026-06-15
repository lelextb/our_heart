import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import 'bloc/info_cubit.dart';
import 'bloc/info_state.dart';
import 'widgets/info_form.dart';

class InfoDetailPage extends StatelessWidget {
  const InfoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entryId = ModalRoute.of(context)?.settings.arguments as int?;
    if (entryId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(Strings.infoTitle)),
        body: const Center(child: Text('Invalid entry.')),
      );
    }

    return BlocBuilder<InfoCubit, InfoState>(
      builder: (context, state) {
        final entryData = state.entries.firstWhere(
          (e) => e.id == entryId,
          orElse: () => InfoEntryData(
            id: -1,
            title: '',
            content: '',
            createdAt: DateTime.now(),
          ),
        );

        if (entryData.id == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text(Strings.infoTitle)),
            body: const Center(child: Text('Entry not found.')),
          );
        }

        return _DetailView(
          entry: entryData,
          onEdit: () => _showEditDialog(context, entryData),
          onDelete: () => _deleteEntry(context, entryId),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, InfoEntryData entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: InfoForm(
          initialTitle: entry.title,
          initialContent: entry.content,
          onSave: (data) {
            context.read<InfoCubit>().update(
                  id: entry.id,
                  title: data.title,
                  content: data.content,
                );
            Navigator.of(context).pop();
          },
          isSaving: false,
        ),
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(Strings.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(Strings.delete)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<InfoCubit>().delete(id);
      Navigator.of(context).pop();
    }
  }
}

class _DetailView extends StatelessWidget {
  final InfoEntryData entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailView({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text(entry.content, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}