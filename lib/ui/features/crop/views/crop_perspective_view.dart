import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Vista para recorte manual de bordes y perspectiva de 4 puntos interactivos
class CropPerspectiveView extends StatefulWidget {
  final String imagePath;

  const CropPerspectiveView({super.key, required this.imagePath});

  @override
  State<CropPerspectiveView> createState() => _CropPerspectiveViewState();
}

class _CropPerspectiveViewState extends State<CropPerspectiveView> {
  // Puntos normalizados (0.0 a 1.0) para las 4 esquinas del documento
  late List<Offset> _corners;

  @override
  void initState() {
    super.initState();
    _resetCorners();
  }

  void _resetCorners() {
    setState(() {
      _corners = [
        const Offset(0.06, 0.06), // Top-Left
        const Offset(0.94, 0.06), // Top-Right
        const Offset(0.94, 0.94), // Bottom-Right
        const Offset(0.06, 0.94), // Bottom-Left
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          AppStrings.cropTitle,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton.icon(
            onPressed: _resetCorners,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            label: const Text(AppStrings.resetCrop, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppStrings.cropSubtitle,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = constraints.maxWidth;
                    final boxHeight = constraints.maxHeight;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagen de fondo a recortar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),

                        // Capa gráfica de dibujo del polígono y guías
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PerspectiveQuadPainter(
                              corners: _corners,
                              boxSize: Size(boxWidth, boxHeight),
                            ),
                          ),
                        ),

                        // Vértices interactivos para arrastrar con el dedo
                        ...List.generate(4, (index) {
                          final point = _corners[index];
                          final posX = point.dx * boxWidth;
                          final posY = point.dy * boxHeight;

                          return Positioned(
                            left: posX - 24,
                            top: posY - 24,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  final newX = (point.dx + details.delta.dx / boxWidth).clamp(0.0, 1.0);
                                  final newY = (point.dy + details.delta.dy / boxHeight).clamp(0.0, 1.0);
                                  _corners[index] = Offset(newX, newY);
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Barra inferior de confirmación
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        // Devolver los 4 puntos normalizados
                        Navigator.pop(context, _corners);
                      },
                      child: const Text(AppStrings.applyCrop),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para dibujar las líneas de perspectiva y cuadrícula interna sobre el documento
class _PerspectiveQuadPainter extends CustomPainter {
  final List<Offset> corners;
  final Size boxSize;

  _PerspectiveQuadPainter({required this.corners, required this.boxSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final p0 = Offset(corners[0].dx * size.width, corners[0].dy * size.height);
    final p1 = Offset(corners[1].dx * size.width, corners[1].dy * size.height);
    final p2 = Offset(corners[2].dx * size.width, corners[2].dy * size.height);
    final p3 = Offset(corners[3].dx * size.width, corners[3].dy * size.height);

    // Contorno del polígono
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    // Sombreado semitransparente fuera del área
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, path);
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // Borde brillante del documento
    final borderPaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // Guías de cuadrícula de tercios interiores (estilo visor de escáner)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double t = 0.33; t < 1.0; t += 0.33) {
      final leftInterp = Offset.lerp(p0, p3, t)!;
      final rightInterp = Offset.lerp(p1, p2, t)!;
      canvas.drawLine(leftInterp, rightInterp, gridPaint);

      final topInterp = Offset.lerp(p0, p1, t)!;
      final bottomInterp = Offset.lerp(p3, p2, t)!;
      canvas.drawLine(topInterp, bottomInterp, gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PerspectiveQuadPainter oldDelegate) => true;
}
