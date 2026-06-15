// lib/data/repositories/gallery_repository.dart

import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../core/utils/image_utils.dart';
import '../database/database.dart';
import '../database/tables.dart';

class GalleryRepository {
  final AppDatabase db;

  const GalleryRepository({required this.db});

  // ---- Categories ----

  /// Returns all categories ordered by creation date descending.
  Future<List<Category>> getAllCategories() async {
    try {
      final categories = await db.select(db.categories).get();
      categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return categories;
    } catch (e, st) {
      dev.log('Failed to load categories', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns a single category by id.
  Future<Category?> getCategoryById(int id) async {
    try {
      return await (db.select(db.categories)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e, st) {
      dev.log('Failed to get category $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Creates a new category. The name must be unique (enforced by DB constraint).
  Future<Category> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final id = await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              name: name.trim().isEmpty ? 'Untitled' : name.trim(),
              description: description != null
                  ? Value(description.trim().isEmpty ? null : description.trim())
                  : const Value.absent(),
            ),
          );
      return (await (db.select(db.categories)..where((t) => t.id.equals(id)))
          .getSingle())!;
    } catch (e, st) {
      dev.log('Failed to create category', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Updates a category name/description.
  Future<void> updateCategory({
    required int id,
    String? name,
    String? description,
  }) async {
    try {
      final companion = CategoriesCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        description: description != null
            ? Value(description.trim().isEmpty ? null : description.trim())
            : const Value.absent(),
      );
      await (db.update(db.categories)..where((t) => t.id.equals(id)))
          .write(companion);
    } catch (e, st) {
      dev.log('Failed to update category $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a category and all its photos.
  Future<void> deleteCategory(int id) async {
    try {
      final photos = await (db.select(db.photos)
            ..where((t) => t.categoryId.equals(id)))
          .get();
      for (final photo in photos) {
        await ImageUtils.deleteImage(photo.filePath);
      }
      await (db.delete(db.photos)..where((t) => t.categoryId.equals(id))).go();
      await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
    } catch (e, st) {
      dev.log('Failed to delete category $id', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ---- Photos ----

  /// Returns all photos for a given category.
  Future<List<Photo>> getPhotosForCategory(int categoryId) async {
    try {
      final photos = await (db.select(db.photos)
            ..where((t) => t.categoryId.equals(categoryId)))
          .get();
      photos.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return photos;
    } catch (e, st) {
      dev.log('Failed to load photos for category $categoryId',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Adds a new photo to an existing category. Returns the created Photo.
  Future<Photo?> addPhotoToCategory(int categoryId) async {
    try {
      final savedPath = await ImageUtils.pickAndCropImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        cropStyle: CropStyle.rectangle,
        prefix: 'gallery',
      );
      if (savedPath == null) return null;

      final thumbPath = await ImageUtils.generateThumbnail(savedPath);

      final companion = PhotosCompanion.insert(
        categoryId: categoryId,
        filePath: savedPath,
        thumbnailPath:
            thumbPath != null ? Value(thumbPath) : Value.absent(),
      );

      final id = await db.into(db.photos).insert(companion);
      return await (db.select(db.photos)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
    } catch (e, st) {
      dev.log('Failed to add photo to category $categoryId',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Deletes a single photo by id.
  Future<void> deletePhoto(int id) async {
    try {
      final photo = await (db.select(db.photos)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (photo != null) {
        await ImageUtils.deleteImage(photo.filePath);
        await (db.delete(db.photos)..where((t) => t.id.equals(id))).go();
      }
    } catch (e, st) {
      dev.log('Failed to delete photo $id', error: e, stackTrace: st);
      rethrow;
    }
  }
}