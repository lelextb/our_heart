// lib/features/gallery/bloc/gallery_state.dart

import 'package:equatable/equatable.dart';

class GalleryState extends Equatable {
  /// List of all categories (albums).
  final List<CategoryData> categories;

  /// List of photos in the currently selected category.
  final List<PhotoData> photos;

  final bool isLoading;
  final String? errorMessage;

  /// IDs of photos currently selected (for bulk delete within a category).
  final Set<int> selectedIds;

  const GalleryState({
    this.categories = const [],
    this.photos = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedIds = const {},
  });

  GalleryState copyWith({
    List<CategoryData>? categories,
    List<PhotoData>? photos,
    bool? isLoading,
    String? errorMessage,
    Set<int>? selectedIds,
  }) {
    return GalleryState(
      categories: categories ?? this.categories,
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }

  @override
  List<Object?> get props =>
      [categories, photos, isLoading, errorMessage, selectedIds];
}

/// Data class for a category (album).
class CategoryData extends Equatable {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String? thumbnailPath; // first photo's thumbnail
  final int photoCount;

  const CategoryData({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.thumbnailPath,
    this.photoCount = 0,
  });

  CategoryData copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    String? thumbnailPath,
    int? photoCount,
  }) {
    return CategoryData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description,
      createdAt: createdAt ?? this.createdAt,
      thumbnailPath: thumbnailPath,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, createdAt, thumbnailPath, photoCount];
}

/// Data class for a single photo.
class PhotoData extends Equatable {
  final int id;
  final int categoryId;
  final String filePath;
  final String? thumbnailPath;
  final DateTime addedAt;

  const PhotoData({
    required this.id,
    required this.categoryId,
    required this.filePath,
    this.thumbnailPath,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [id, categoryId, filePath, thumbnailPath, addedAt];
}