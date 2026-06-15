import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../shared_widgets/empty_state_widget.dart';
import '../../shared_widgets/loading_indicator.dart';
import 'bloc/info_cubit.dart';
import 'bloc/info_state.dart';
import 'widgets/info_card.dart';

/// Displays all Info entries in a scrollable grid with glassmorphic cards.
/// Has its own back button in the AppBar.
class InfoListPage extends StatelessWidget {
  const InfoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InfoListBody();
  }
}

class _InfoListBody extends StatefulWidget {
  const _InfoListBody();

  @override
  State<_InfoListBody> createState() => _InfoListBodyState();
}

class _InfoListBodyState extends State<_InfoListBody> {
  @override
  void initState() {
    super.initState();
    context.read<InfoCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.infoTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).pushNamed('/info/add'),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<InfoCubit, InfoState>(
      builder: (context, state) {
        if (state.isLoading && state.entries.isEmpty) {
          return const LoadingIndicator(message: Strings.loading);
        }
        if (state.errorMessage != null && state.entries.isEmpty) {
          return EmptyStateWidget(
            message: state.errorMessage!,
            icon: Icons.error_outline,
            onAction: () => context.read<InfoCubit>().load(),
            actionLabel: Strings.retry,
          );
        }
        if (state.entries.isEmpty) {
          return EmptyStateWidget(
            message: Strings.noData,
            icon: Icons.note_add_outlined,
            onAction: () => Navigator.of(context).pushNamed('/info/add'),
            actionLabel: Strings.infoAddNew,
          );
        }
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: state.entries.length,
            itemBuilder: (ctx, index) {
              final entry = state.entries[index];
              return InfoCard(
                entry: entry,
                onTap: () => Navigator.of(context).pushNamed(
                  '/info/detail',
                  arguments: entry.id,
                ),
              );
            },
          ),
        );
      },
    );
  }
}