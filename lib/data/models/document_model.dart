import 'scanned_page_model.dart';

/// Modelo de datos que representa un documento completo compuesto por una o varias páginas
class DocumentModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScannedPageModel> pages;
  final String? pdfPath;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.pages = const [],
    this.pdfPath,
  });

  int get pageCount => pages.length;

  String? get thumbnailPath {
    if (pages.isEmpty) return null;
    return pages.first.processedImagePath;
  }

  DocumentModel copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ScannedPageModel>? pages,
    String? pdfPath,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pages': pages.map((p) => p.toJson()).toList(),
      'pdfPath': pdfPath,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'] as List<dynamic>? ?? [];
    final pagesList = rawPages
        .map((p) => ScannedPageModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();

    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      pages: pagesList,
      pdfPath: json['pdfPath'] as String?,
    );
  }
}
