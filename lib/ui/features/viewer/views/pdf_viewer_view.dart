import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/document_model.dart';
import '../../../../data/repositories/document_repository.dart';
import '../../../../data/services/share_export_service.dart';
import '../../../core_widgets/custom_app_bar.dart';
import '../../../core_widgets/loading_indicator.dart';

/// Pantalla para visualización interactiva y exportación local del archivo PDF
class PdfViewerView extends StatefulWidget {
  final String documentId;
  final DocumentRepository repository;
  final ShareExportService shareExportService;

  const PdfViewerView({
    super.key,
    required this.documentId,
    required this.repository,
    required this.shareExportService,
  });

  @override
  State<PdfViewerView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfViewerView> {
  DocumentModel? _document;
  String? _pdfPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await widget.repository.getDocument(widget.documentId);
      if (doc == null) {
        throw Exception('Documento no encontrado.');
      }

      String? path = doc.pdfPath;
      if (path == null || !File(path).existsSync()) {
        path = await widget.repository.compileDocumentPdf(doc.id);
      }

      setState(() {
        _document = doc;
        _pdfPath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al generar la vista previa del PDF: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfPath == null || _document == null) return;
    try {
      await widget.shareExportService.sharePdf(
        pdfPath: _pdfPath!,
        documentTitle: _document!.title,
      );
    } catch (e) {
      _showSnackbar('Error al compartir: $e', isError: true);
    }
  }

  Future<void> _saveToDownloads() async {
    if (_pdfPath == null || _document == null) return;
    try {
      final savedPath = await widget.shareExportService.exportPdfToDownloads(
        sourcePdfPath: _pdfPath!,
        fileName: _document!.title,
      );
      _showSnackbar('PDF guardado en: $savedPath');
    } catch (e) {
      _showSnackbar('Error al exportar a Descargas: $e', isError: true);
    }
  }

  Future<void> _shareImages() async {
    if (_document == null || _document!.pages.isEmpty) return;
    try {
      final paths = _document!.pages.map((p) => p.processedImagePath).toList();
      await widget.shareExportService.shareImages(
        imagePaths: paths,
        title: _document!.title,
      );
    } catch (e) {
      _showSnackbar('Error al compartir imágenes: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _document?.title ?? AppStrings.pdfViewerTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: AppStrings.saveToDownloads,
            onPressed: _saveToDownloads,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: AppStrings.shareDocument,
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Renderizando documento PDF local...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPdf,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfPath == null || !File(_pdfPath!).existsSync()) {
      return const Center(child: Text('Archivo PDF no disponible'));
    }

    final fileBytes = File(_pdfPath!).readAsBytesSync();

    return PdfPreview(
      build: (format) => fileBytes,
      useActions: false, // Usamos nuestra propia barra de acciones personalizada y en español
      canChangePageFormat: false,
      canChangeOrientation: false,
      loadingWidget: const LoadingIndicator(message: 'Cargando páginas...'),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareImages,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Imágenes JPG', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _sharePdf,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Compartir PDF', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
