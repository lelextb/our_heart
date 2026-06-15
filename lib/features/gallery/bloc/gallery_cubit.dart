// lib/features/gallery/bloc/gallery_cubit.dart

import 'dart:developer' as dev;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/image_utils.dart';
import '../../../data/database/tables.dart';
import '../../../data/database/database.dart';
import '../../../data/repositories/gallery_repository.dart';
import 'gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  GalleryCubit({required this.repository}) : super(const GalleryState());

  final GalleryRepository repository;

  // ---- Categories ----

  Future<void> loadCategories() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final categories = await repository.getAllCategories();
      final data = <CategoryData>[];
      for (final c in categories) {
        final photos = await repository.getPhotosForCategory(c.id);
        data.add(CategoryData(
          id: c.id,
          name: c.name,
          description: c.description,
          createdAt: c.createdAt,
          thumbnailPath: photos.isNotEmpty ? photos.first.thumbnailPath : null,
          photoCount: photos.length,
        ));
      }
      emit(state.copyWith(isLoading: false, categories: data));
    } catch (e, st) {
      dev.log('GalleryCubit loadCategories error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not load categories.'));
    }
  }

  Future<void> loadPhotos({required int categoryId}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final photos = await repository.getPhotosForCategory(categoryId);
      final data = photos
          .map((p) => PhotoData(
                id: p.id,
                categoryId: p.categoryId,
                filePath: p.filePath,
                thumbnailPath: p.thumbnailPath,
                addedAt: p.addedAt,
              ))
          .toList();
      emit(state.copyWith(isLoading: false, photos: data));
    } catch (e, st) {
      dev.log('GalleryCubit loadPhotos error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not load photos.'));
    }
  }

  Future<void> createCategory({
    required String name,
    String? description,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.createCategory(name: name, description: description);
      await loadCategories();
    } catch (e, st) {
      dev.log('GalleryCubit createCategory error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Could not create category. Name may already exist.'));
    }
  }

  Future<void> updateCategory({
    required int id,
    String? name,
    String? description,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.updateCategory(
          id: id, name: name, description: description);
      await loadCategories();
    } catch (e, st) {
      dev.log('GalleryCubit updateCategory error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not update category.'));
    }
  }

  Future<void> deleteCategory(int id) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.deleteCategory(id);
      await loadCategories();
    } catch (e, st) {
      dev.log('GalleryCubit deleteCategory error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not delete category.'));
    }
  }

  // ---- Photos ----

  Future<bool> addPhotoToCategory(int categoryId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final photo = await repository.addPhotoToCategory(categoryId);
      if (photo != null) {
        await loadPhotos(categoryId: categoryId);
        await loadCategories(); // refresh category list
        return true;
      } else {
        emit(state.copyWith(isLoading: false));
        return false;
      }
    } catch (e, st) {
      dev.log('GalleryCubit addPhotoToCategory error',
          error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not add photo.'));
      return false;
    }
  }

  Future<int> addMultiplePhotosToCategory(int categoryId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    int added = 0;
    try {
      final picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage(imageQuality: 95);
      if (files.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return 0;
      }

      for (final file in files) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imgDir = Directory(p.join(appDir.path, 'images'));
          if (!await imgDir.exists()) await imgDir.create(recursive: true);
          final fileName =
              'gallery_${DateTime.now().millisecondsSinceEpoch}_$added.png';
          final destPath = p.join(imgDir.path, fileName);
          await File(file.path).copy(destPath);

          final thumbPath = await ImageUtils.generateThumbnail(destPath);

          final companion = PhotosCompanion.insert(
            categoryId: categoryId,
            filePath: destPath,
            thumbnailPath:
                thumbPath != null ? Value(thumbPath) : Value.absent(),
          );
          await repository.db.into(repository.db.photos).insert(companion);
          added++;
        } catch (e) {
          dev.log('Failed to add one photo: $e');
        }
      }

      if (added > 0) {
        await loadPhotos(categoryId: categoryId);
        await loadCategories();
      } else {
        emit(state.copyWith(isLoading: false));
      }
      return added;
    } catch (e, st) {
      dev.log('GalleryCubit addMultiplePhotos error',
          error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not add photos.'));
      return added;
    }
  }

  Future<void> deletePhoto(int id, int categoryId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      await repository.deletePhoto(id);
      await loadPhotos(categoryId: categoryId);
      await loadCategories();
    } catch (e, st) {
      dev.log('GalleryCubit deletePhoto error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not delete photo.'));
    }
  }

  void toggleSelection(int id) {
    final selectedIds = Set<int>.from(state.selectedIds);
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    emit(state.copyWith(selectedIds: selectedIds));
  }

  void clearSelection() {
    emit(state.copyWith(selectedIds: const {}));
  }

  Future<void> deleteSelected({required int categoryId}) async {
    if (state.selectedIds.isEmpty) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      for (final id in state.selectedIds) {
        await repository.deletePhoto(id);
      }
      emit(state.copyWith(selectedIds: const {}));
      await loadPhotos(categoryId: categoryId);
      await loadCategories();
    } catch (e, st) {
      dev.log('GalleryCubit deleteSelected error', error: e, stackTrace: st);
      emit(state.copyWith(
          isLoading: false, errorMessage: 'Could not delete photos.'));
    }
  }
}