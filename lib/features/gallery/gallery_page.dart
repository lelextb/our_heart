// lib/features/gallery/gallery_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/glassmorphism.dart';
import '../../shared_widgets/empty_state_widget.dart';
import '../../shared_widgets/loading_indicator.dart';
import 'bloc/gallery_cubit.dart';
import 'bloc/gallery_state.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GalleryBody();
  }
}

class _GalleryBody extends StatefulWidget {
  const _GalleryBody();

  @override
  State<_GalleryBody> createState() => _GalleryBodyState();
}

class _GalleryBodyState extends State<_GalleryBody> {
  @override
  void initState() {
    super.initState();
    context.read<GalleryCubit>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(Strings.galleryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _showQuickAddDialog(context),
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCategoryDialog(context),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<GalleryCubit, GalleryState>(
      builder: (context, state) {
        if (state.isLoading && state.categories.isEmpty) {
          return const LoadingIndicator(message: Strings.loading);
        }
        if (state.errorMessage != null && state.categories.isEmpty) {
          return EmptyStateWidget(
            message: state.errorMessage!,
            icon: Icons.error_outline,
            onAction: () => context.read<GalleryCubit>().loadCategories(),
            actionLabel: Strings.retry,
          );
        }
        if (state.categories.isEmpty) {
          return EmptyStateWidget(
            message: 'No albums yet!',
            icon: Icons.photo_album_outlined,
            onAction: () => _showCreateCategoryDialog(context),
            actionLabel: 'Create Album',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          itemCount: state.categories.length,
          itemBuilder: (ctx, index) {
            final category = state.categories[index];
            return _CategoryHeroCard(
              name: category.name,
              description: category.description,
              thumbnailPath: category.thumbnailPath,
              photoCount: category.photoCount,
              onTap: () => Navigator.of(context).pushNamed(
                '/gallery/album',
                arguments: category.id,
              ),
              onAddPhoto: () => _addPhotoToCategory(context, category.id),
            );
          },
        );
      },
    );
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Album Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
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
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              context.read<GalleryCubit>().createCategory(
                    name: name,
                    description:
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text(Strings.save),
          ),
        ],
      ),
    );
  }

  void _addPhotoToCategory(BuildContext context, int categoryId) async {
    final cubit = context.read<GalleryCubit>();
    final success = await cubit.addPhotoToCategory(categoryId);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo added!')),
      );
    }
  }

  void _showQuickAddDialog(BuildContext context) {
    final cubit = context.read<GalleryCubit>();
    final categories = cubit.state.categories;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add photo to…'),
        children: [
          ...categories.map((c) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(ctx);
                  _addPhotoToCategory(context, c.id);
                },
                child: ListTile(
                  title: Text(c.name),
                  subtitle: c.description != null ? Text(c.description!) : null,
                  leading: const Icon(Icons.photo_album),
                ),
              )),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No albums yet. Create one first!'),
            ),
        ],
      ),
    );
  }
}

/// A large album card with the first photo as a background, overlaid
/// glassmorphic text, and an add‑photo button.
class _CategoryHeroCard extends StatelessWidget {
  const _CategoryHeroCard({
    required this.name,
    required this.description,
    required this.thumbnailPath,
    required this.photoCount,
    required this.onTap,
    required this.onAddPhoto,
  });

  final String name;
  final String? description;
  final String? thumbnailPath;
  final int photoCount;
  final VoidCallback onTap;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = thumbnailPath != null && File(thumbnailPath!).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or solid color
                if (hasImage)
                  Image.file(
                    File(thumbnailPath!),
                    fit: BoxFit.cover,
                  )
                else
                  Container(color: AppColors.primary.withOpacity(0.1)),
                // Dark gradient overlay for legibility
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title, description, photo count
                Positioned(
                  left: 16,
                  bottom: 16,
                  right: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null && description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '$photoCount photo${photoCount == 1 ? '' : 's'}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                // Add photo button (top right)
                Positioned(
                  top: 12,
                  right: 8,
                  child: GlassmorphicContainer(
                    width: 44,
                    height: 44,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(22),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.add_a_photo_outlined,
                          size: 22, color: Colors.white),
                      onPressed: onAddPhoto,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}