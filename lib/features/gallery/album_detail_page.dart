import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import '../../shared_widgets/empty_state_widget.dart';
import '../../shared_widgets/loading_indicator.dart';
import 'bloc/gallery_cubit.dart';
import 'bloc/gallery_state.dart';
import 'widgets/photo_grid.dart';
import 'widgets/photo_viewer.dart';

class AlbumDetailPage extends StatelessWidget {
  const AlbumDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the category id from the route arguments
    final categoryId = ModalRoute.of(context)?.settings.arguments as int?;
    if (categoryId == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Album')),
        body: const Center(child: Text('Invalid album.')),
      );
    }

    return BlocProvider.value(
      value: context.read<GalleryCubit>(),
      child: _AlbumDetailBody(categoryId: categoryId),
    );
  }
}

class _AlbumDetailBody extends StatefulWidget {
  const _AlbumDetailBody({required this.categoryId});
  final int categoryId;

  @override
  State<_AlbumDetailBody> createState() => _AlbumDetailBodyState();
}

class _AlbumDetailBodyState extends State<_AlbumDetailBody> {
  late final GalleryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<GalleryCubit>();
    _cubit.loadPhotos(categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final category = _cubit.state.categories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => CategoryData(
        id: -1,
        name: 'Album',
        description: null,
        createdAt: DateTime.now(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCategoryDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () => _addSinglePhoto(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _addMultiplePhotos(context),
          ),
        ],
      ),
      body: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          if (state.isLoading && state.photos.isEmpty) {
            return const LoadingIndicator(message: Strings.loading);
          }
          if (state.errorMessage != null && state.photos.isEmpty) {
            return EmptyStateWidget(
              message: state.errorMessage!,
              icon: Icons.error_outline,
              onAction: () =>
                  _cubit.loadPhotos(categoryId: widget.categoryId),
              actionLabel: Strings.retry,
            );
          }
          if (state.photos.isEmpty) {
            return EmptyStateWidget(
              message: 'No photos in this album.',
              icon: Icons.photo_library_outlined,
              onAction: () => _addSinglePhoto(context),
              actionLabel: 'Add Photo',
            );
          }

          final items = state.photos
              .map((p) => PhotoGridItem(
                    id: p.id,
                    filePath: p.filePath,
                    thumbnailPath: p.thumbnailPath,
                  ))
              .toList();

          return PhotoGrid(
            photos: items,
            selectedIds: state.selectedIds,
            onPhotoTap: (id) {
              if (state.selectedIds.isNotEmpty) {
                _cubit.toggleSelection(id);
              } else {
                final index = state.photos.indexWhere((p) => p.id == id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _SwipeablePhotoViewer(
                      initialIndex: index,
                      photos: state.photos,
                      onDelete: (photoId) {
                        _cubit.deletePhoto(photoId, widget.categoryId);
                      },
                    ),
                  ),
                );
              }
            },
            onPhotoLongPress: (id) {
              _cubit.toggleSelection(id);
            },
            onDeleteSelected: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(Strings.galleryDeleteConfirmation),
                  content: Text(
                      '${state.selectedIds.length} photo(s) selected.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(Strings.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(Strings.delete,
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                _cubit.deleteSelected(categoryId: widget.categoryId);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _addSinglePhoto(BuildContext context) async {
    final success = await _cubit.addPhotoToCategory(widget.categoryId);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo added!')),
      );
    }
  }

  Future<void> _addMultiplePhotos(BuildContext context) async {
    final count = await _cubit.addMultiplePhotosToCategory(widget.categoryId);
    if (mounted && count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count photo(s) added!')),
      );
    }
  }

  void _showEditCategoryDialog(BuildContext context) {
    final category = _cubit.state.categories.firstWhere(
      (c) => c.id == widget.categoryId,
      orElse: () => CategoryData(
        id: -1,
        name: 'Album',
        description: null,
        createdAt: DateTime.now(),
      ),
    );
    final nameCtrl = TextEditingController(text: category.name);
    final descCtrl = TextEditingController(text: category.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Album'),
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
              decoration: const InputDecoration(labelText: 'Description (optional)'),
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
              _cubit.updateCategory(
                id: widget.categoryId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text(Strings.save),
          ),
        ],
      ),
    );
  }
}

class _SwipeablePhotoViewer extends StatelessWidget {
  const _SwipeablePhotoViewer({
    required this.initialIndex,
    required this.photos,
    required this.onDelete,
  });

  final int initialIndex;
  final List<PhotoData> photos;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (ctx, index) {
          final photo = photos[index];
          return PhotoViewer(
            filePath: photo.filePath,
            onDelete: () {
              onDelete(photo.id);
              if (photos.length <= 1) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      ),
    );
  }
}