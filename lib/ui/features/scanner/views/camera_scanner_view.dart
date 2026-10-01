import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/repositories/document_repository.dart';
import '../../../../data/services/share_export_service.dart';
import '../../../core_widgets/loading_indicator.dart';
import '../../crop/views/crop_perspective_view.dart';
import '../../editor/views/document_editor_view.dart';
import '../view_models/scanner_view_model.dart';

/// Pantalla con cámara guiada en vivo para captura de documentos multi-página
class CameraScannerView extends StatefulWidget {
  final DocumentRepository repository;
  final ShareExportService shareExportService;

  const CameraScannerView({
    super.key,
    required this.repository,
    required this.shareExportService,
  });

  @override
  State<CameraScannerView> createState() => _CameraScannerViewState();
}

class _CameraScannerViewState extends State<CameraScannerView> with WidgetsBindingObserver {
  late final ScannerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = ScannerViewModel(repository: widget.repository);
    _viewModel.initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _viewModel.initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    final photoPath = await _viewModel.capturePage();
    if (photoPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Página ${_viewModel.pageCount} capturada'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _finishScanning() async {
    if (_viewModel.pageCount == 0) return;

    final doc = await _viewModel.finishScanning();
    if (doc != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentEditorView(
            documentId: doc.id,
            repository: widget.repository,
            shareExportService: widget.shareExportService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (!_viewModel.hasPermission) {
            return _buildPermissionRequest();
          }

          if (!_viewModel.isInitialized || _viewModel.cameraController == null) {
            return const LoadingIndicator(message: 'Iniciando cámara local...');
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Visor de cámara
              Center(
                child: CameraPreview(_viewModel.cameraController!),
              ),

              // Superposición gráfica: marco guía para el documento
              _buildDocumentFrameGuide(),

              // Barra superior de controles (Atrás, Modo de Flash)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Badge contador de páginas
                        if (_viewModel.pageCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_viewModel.pageCount} ${_viewModel.pageCount == 1 ? "página" : "páginas"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        // Botón de Flash
                        IconButton(
                          style: IconButton.styleFrom(backgroundColor: Colors.black54),
                          icon: Icon(
                            _getFlashIcon(_viewModel.currentFlashMode),
                            color: Colors.white,
                          ),
                          onPressed: _viewModel.toggleFlash,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Barra inferior de captura y finalización
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87, Colors.black],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Miniatura de la última página o botón deshacer
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: _viewModel.pageCount > 0
                            ? GestureDetector(
                                onTap: () async {
                                  // Recorte opcional sobre la última captura
                                  final lastPath = _viewModel.capturedImages.last;
                                  final corners = await Navigator.push<List<Offset>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CropPerspectiveView(imagePath: lastPath),
                                    ),
                                  );
                                  if (corners != null) {
                                    // Recorte confirmado
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_viewModel.capturedImages.last),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Botón principal de disparo
                      GestureDetector(
                        onTap: _viewModel.isCapturing ? null : _handleCapture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _viewModel.isCapturing ? Colors.grey : AppColors.primaryLight,
                            ),
                            child: _viewModel.isCapturing
                                ? const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                          ),
                        ),
                      ),

                      // Botón Finalizar escaneo
                      SizedBox(
                        width: 72,
                        child: _viewModel.pageCount > 0
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _finishScanning,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, size: 20),
                                    Text('Listo', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentFrameGuide() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.84,
          height: MediaQuery.of(context).size.height * 0.62,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Esquinas acentuadas
              Positioned(
                top: 0,
                left: 0,
                child: _cornerMark(top: true, left: true),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _cornerMark(top: true, left: false),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _cornerMark(top: false, left: true),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _cornerMark(top: false, left: false),
              ),
              // Mensaje centrado tenue
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    AppStrings.alignDocumentGuide,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cornerMark({required bool top, required bool left}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.primaryLight, width: 4) : BorderSide.none,
        ),
      ),
    );
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.torch:
      case FlashMode.always:
        return Icons.flash_on_rounded;
    }
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 64),
            const SizedBox(height: 18),
            const Text(
              AppStrings.cameraPermissionRequired,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _viewModel.initCamera,
              child: const Text(AppStrings.grantPermission),
            ),
          ],
        ),
      ),
    );
  }
}
