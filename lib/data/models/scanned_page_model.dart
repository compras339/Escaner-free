import 'filter_type.dart';

/// Modelo de datos para una página individual dentro de un documento escaneado
class ScannedPageModel {
  final String id;
  final String originalImagePath;
  final String processedImagePath;
  final FilterType filter;
  final int rotationAngle; // 0, 90, 180, 270
  final int pageNumber;
  final DateTime createdAt;

  const ScannedPageModel({
    required this.id,
    required this.originalImagePath,
    required this.processedImagePath,
    this.filter = FilterType.original,
    this.rotationAngle = 0,
    required this.pageNumber,
    required this.createdAt,
  });

  ScannedPageModel copyWith({
    String? id,
    String? originalImagePath,
    String? processedImagePath,
    FilterType? filter,
    int? rotationAngle,
    int? pageNumber,
    DateTime? createdAt,
  }) {
    return ScannedPageModel(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      filter: filter ?? this.filter,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalImagePath': originalImagePath,
      'processedImagePath': processedImagePath,
      'filter': filter.name,
      'rotationAngle': rotationAngle,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ScannedPageModel.fromJson(Map<String, dynamic> json) {
    return ScannedPageModel(
      id: json['id'] as String,
      originalImagePath: json['originalImagePath'] as String,
      processedImagePath: json['processedImagePath'] as String,
      filter: FilterType.values.firstWhere(
        (f) => f.name == json['filter'],
        orElse: () => FilterType.original,
      ),
      rotationAngle: (json['rotationAngle'] as num?)?.toInt() ?? 0,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
