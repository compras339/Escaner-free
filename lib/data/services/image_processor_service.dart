import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/filter_type.dart';

/// Servicio de procesamiento de imágenes 100% local y offline
/// Utiliza algoritmos de visión y renderizado digital sobre CPU local
class ImageProcessorService {
  /// Aplica rotación y filtro a una imagen de origen y la guarda en destino
  Future<String> processImage({
    required String inputPath,
    required String outputPath,
    FilterType filter = FilterType.original,
    int rotationDegrees = 0,
  }) async {
    return compute(_processImageIsolate, _ProcessImageParams(
      inputPath: inputPath,
      outputPath: outputPath,
      filter: filter,
      rotationDegrees: rotationDegrees,
    ));
  }

  /// Recorta una imagen a partir de 4 puntos de coordenadas normalizadas (0.0 a 1.0)
  Future<String> cropPerspective({
    required String inputPath,
    required String outputPath,
    required List<Offset> normalizedCorners, // [topLeft, topRight, bottomRight, bottomLeft]
  }) async {
    return compute(_cropQuadIsolate, _CropParams(
      inputPath: inputPath,
      outputPath: outputPath,
      corners: normalizedCorners,
    ));
  }

  /// Genera una miniatura optimizada para previsualizaciones rápidas en listas
  Future<String> createThumbnail({
    required String inputPath,
    required String thumbnailPath,
    int maxDimension = 300,
  }) async {
    return compute(_createThumbnailIsolate, _ThumbnailParams(
      inputPath: inputPath,
      thumbnailPath: thumbnailPath,
      maxDimension: maxDimension,
    ));
  }
}

// Parámetros para cómputo en Isolate secundario (evita bloquear la UI de Flutter)
class _ProcessImageParams {
  final String inputPath;
  final String outputPath;
  final FilterType filter;
  final int rotationDegrees;

  _ProcessImageParams({
    required this.inputPath,
    required this.outputPath,
    required this.filter,
    required this.rotationDegrees,
  });
}

class _CropParams {
  final String inputPath;
  final String outputPath;
  final List<Offset> corners;

  _CropParams({
    required this.inputPath,
    required this.outputPath,
    required this.corners,
  });
}

class _ThumbnailParams {
  final String inputPath;
  final String thumbnailPath;
  final int maxDimension;

  _ThumbnailParams({
    required this.inputPath,
    required this.thumbnailPath,
    required this.maxDimension,
  });
}

/// Función de Isolate para rotación y aplicación de filtros
Future<String> _processImageIsolate(_ProcessImageParams params) async {
  final bytes = await File(params.inputPath).readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception('No se pudo decodificar la imagen: ${params.inputPath}');
  }

  // 1. Corregir orientación / Rotación
  if (params.rotationDegrees % 360 != 0) {
    image = img.copyRotate(image, angle: params.rotationDegrees);
  }

  // 2. Aplicar filtro seleccionado
  switch (params.filter) {
    case FilterType.original:
      // Conservar imagen original sin modificaciones de color
      break;

    case FilterType.grayscale:
      // Conversión a escala de grises de 8 bits
      image = img.grayscale(image);
      break;

    case FilterType.blackAndWhite:
      // Algoritmo de binarización adaptativo de alto contraste para documentos
      // Limpia sombras de fondo y resalta la tinta/texto en negro puro (0) y papel blanco puro (255)
      image = img.grayscale(image);
      
      // Calcular luminosidad media para umbral dinámico
      int totalLuminance = 0;
      int pixelCount = 0;
      const step = 4; // Muestreo rápido para rendimiento
      for (int y = 0; y < image.height; y += step) {
        for (int x = 0; x < image.width; x += step) {
          final pixel = image.getPixel(x, y);
          totalLuminance += pixel.r.toInt();
          pixelCount++;
        }
      }
      
      final averageLuminance = pixelCount > 0 ? (totalLuminance / pixelCount) : 128.0;
      // Ajuste de umbral: ligeramente por debajo de la media para evitar perder trazos finos
      final threshold = (averageLuminance * 0.90).clamp(80.0, 185.0);

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final lum = pixel.r.toInt();
          final val = lum > threshold ? 255 : 0;
          image.setPixelRgba(x, y, val, val, val, 255);
        }
      }
      break;

    case FilterType.magicColor:
      // Filtro de realce de documento a color (aumento de contraste, saturación y balance)
      image = img.adjustColor(
        image,
        contrast: 1.35,
        saturation: 1.25,
        brightness: 1.05,
      );
      break;
  }

  // 3. Guardar imagen procesada en formato JPEG optimizado
  final outputBytes = img.encodeJpg(image, quality: 90);
  final outputFile = File(params.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(outputBytes);

  return outputFile.path;
}

/// Función de Isolate para recorte poligonal
Future<String> _cropQuadIsolate(_CropParams params) async {
  final bytes = await File(params.inputPath).readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception('No se pudo decodificar la imagen para recorte.');
  }

  final width = image.width.toDouble();
  final height = image.height.toDouble();

  // Convertir puntos normalizados a coordenadas de píxeles reales
  final p0 = Offset(params.corners[0].dx * width, params.corners[0].dy * height);
  final p1 = Offset(params.corners[1].dx * width, params.corners[1].dy * height);
  final p2 = Offset(params.corners[2].dx * width, params.corners[2].dy * height);
  final p3 = Offset(params.corners[3].dx * width, params.corners[3].dy * height);

  // Obtener caja delimitadora envolvente (Bounding Box)
  final minX = [p0.dx, p1.dx, p2.dx, p3.dx].reduce(math.min).clamp(0.0, width - 1).toInt();
  final maxX = [p0.dx, p1.dx, p2.dx, p3.dx].reduce(math.max).clamp(0.0, width).toInt();
  final minY = [p0.dy, p1.dy, p2.dy, p3.dy].reduce(math.min).clamp(0.0, height - 1).toInt();
  final maxY = [p0.dy, p1.dy, p2.dy, p3.dy].reduce(math.max).clamp(0.0, height).toInt();

  final cropWidth = math.max(1, maxX - minX);
  final cropHeight = math.max(1, maxY - minY);

  // Recortar la región seleccionada
  final cropped = img.copyCrop(
    image,
    x: minX,
    y: minY,
    width: cropWidth,
    height: cropHeight,
  );

  final outputBytes = img.encodeJpg(cropped, quality: 92);
  final outputFile = File(params.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(outputBytes);

  return outputFile.path;
}

/// Función de Isolate para crear miniatura
Future<String> _createThumbnailIsolate(_ThumbnailParams params) async {
  final bytes = await File(params.inputPath).readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception('Error al decodificar imagen para miniatura.');
  }

  final thumbnail = img.copyResize(
    image,
    width: image.width > image.height ? params.maxDimension : null,
    height: image.height >= image.width ? params.maxDimension : null,
  );

  final outputBytes = img.encodeJpg(thumbnail, quality: 75);
  final outputFile = File(params.thumbnailPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(outputBytes);

  return outputFile.path;
}
