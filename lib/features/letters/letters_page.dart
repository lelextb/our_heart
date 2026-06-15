import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../shared_widgets/empty_state_widget.dart';
import '../../shared_widgets/loading_indicator.dart';
import 'bloc/letters_cubit.dart';
import 'bloc/letters_state.dart';

/// Displays all letters as glassmorphic cards with title, date, and a short
/// body preview.  Tapping a card opens the dedicated edit page.  The FAB
/// opens the add page.
class LettersPage extends StatelessWidget {
  const LettersPage({super.key});

  @override
  Widget build(BuildContext context) => const _LettersBody();
}

class _LettersBody extends StatefulWidget {
  const _LettersBody();

  @override
  State<_LettersBody> createState() => _LettersBodyState();
}

class _LettersBodyState extends State<_LettersBody> {
  @override
  void initState() {
    super.initState();
    context.read<LettersCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.lettersTitle),
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed('/letters/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<LettersCubit, LettersState>(
      builder: (context, state) {
        if (state.isLoading && state.letters.isEmpty) {
          return const LoadingIndicator(message: Strings.loading);
        }
        if (state.errorMessage != null && state.letters.isEmpty) {
          return EmptyStateWidget(
            message: state.errorMessage!,
            icon: Icons.error_outline,
            onAction: () => context.read<LettersCubit>().load(),
            actionLabel: Strings.retry,
          );
        }
        if (state.letters.isEmpty) {
          return EmptyStateWidget(
            message: Strings.lettersNoLetters,
            icon: Icons.email_outlined,
            onAction: () =>
                Navigator.of(context).pushNamed('/letters/add'),
            actionLabel: Strings.lettersAdd,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: state.letters.length,
          itemBuilder: (ctx, index) {
            final letter = state.letters[index];
            return _LetterCard(
              letter: letter,
              onTap: () => Navigator.of(context).pushNamed(
                '/letters/edit',
                arguments: letter,
              ),
              onDelete: () => _confirmDelete(context, letter.id),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Letter'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<LettersCubit>().delete(id);
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

/// Glassmorphic card for a letter, showing title, date, and a short preview.
class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.letter,
    required this.onTap,
    required this.onDelete,
  });

  final LetterData letter;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final glassBg = isDark
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.primary.withOpacity(0.08);

    final dateStr =
        '${letter.createdAt.day}/${letter.createdAt.month}/${letter.createdAt.year}';
    final preview = letter.content.length > 120
        ? '${letter.content.substring(0, 120)}…'
        : letter.content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassmorphicContainer(
          backgroundColor: glassBg,
          borderColor: AppColors.primary.withOpacity(0.3),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: theme.colorScheme.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}