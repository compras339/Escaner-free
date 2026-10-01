import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

/// Tipos de filtros de procesamiento de imagen disponibles
enum FilterType {
  original,
  blackAndWhite,
  grayscale,
  magicColor;

  String get displayName {
    switch (this) {
      case FilterType.original:
        return AppStrings.filterOriginal;
      case FilterType.blackAndWhite:
        return AppStrings.filterBinarized;
      case FilterType.grayscale:
        return AppStrings.filterGrayscale;
      case FilterType.magicColor:
        return AppStrings.filterMagicColor;
    }
  }

  String get description {
    switch (this) {
      case FilterType.original:
        return 'Sin modificaciones';
      case FilterType.blackAndWhite:
        return AppStrings.filterBinarizedDesc;
      case FilterType.grayscale:
        return AppStrings.filterGrayscaleDesc;
      case FilterType.magicColor:
        return AppStrings.filterMagicColorDesc;
    }
  }

  IconData get icon {
    switch (this) {
      case FilterType.original:
        return Icons.photo_original_outlined;
      case FilterType.blackAndWhite:
        return Icons.contrast_rounded;
      case FilterType.grayscale:
        return Icons.monochrome_photos_outlined;
      case FilterType.magicColor:
        return Icons.auto_awesome_rounded;
    }
  }
}
