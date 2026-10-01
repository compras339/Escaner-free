import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/filter_type.dart';
import '../../../../data/models/scanned_page_model.dart';
import '../../../../data/repositories/document_repository.dart';
import '../../../../data/services/share_export_service.dart';
import '../../../core_widgets/custom_app_bar.dart';
import '../../../core_widgets/loading_indicator.dart';
import '../../crop/views/crop_perspective_view.dart';
import '../../scanner/views/camera_scanner_view.dart';
import '../../viewer/views/pdf_viewer_view.dart';
import '../view_models/document_editor_view_model.dart';
import 'page_filter_view.dart';

/// Pantalla de edición y organización de páginas del documento
class DocumentEditorView extends StatefulWidget {
  final String documentId;
  final DocumentRepository repository;
  final ShareExportService shareExportService;

  const DocumentEditorView({
    super.key,
    required this.documentId,
    required this.repository,
    required this.shareExportService,
  });

  @override
  State<DocumentEditorView> createState() => _DocumentEditorViewState();
}

class _DocumentEditorViewState extends State<DocumentEditorView> {
  late final DocumentEditorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DocumentEditorViewModel(
      repository: widget.repository,
      documentId: widget.documentId,
    );
    _viewModel.loadDocument();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showRenameDialog() {
    final titleController = TextEditingController(text: _viewModel.document?.title ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar Documento'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej. Factura Septiembre',
            labelText: 'Título del documento',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                _viewModel.renameDocument(newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.saveChanges),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePage(ScannedPageModel page) {
    if (_viewModel.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un documento debe contener al menos 1 página.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Página'),
        content: Text('¿Deseas eliminar permanentemente la página ${page.pageNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _viewModel.deletePage(page.id);
            },
            child: const Text(AppStrings.confirmDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCompilePdf() async {
    final pdfPath = await _viewModel.compilePdf();
    if (pdfPath != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerView(
            documentId: widget.documentId,
            repository: widget.repository,
            shareExportService: widget.shareExportService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final doc = _viewModel.document;

        return Scaffold(
          appBar: CustomAppBar(
            title: doc?.title ?? AppStrings.editorTitle,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                tooltip: 'Renombrar título',
                onPressed: _showRenameDialog,
              ),
            ],
          ),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const LoadingIndicator(message: 'Cargando páginas...');
    }

    if (_viewModel.isProcessingAction) {
      return const LoadingIndicator(message: 'Procesando imagen localmente...');
    }

    if (_viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_viewModel.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _viewModel.loadDocument,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final pages = _viewModel.pages;

    return Column(
      children: [
        // Indicador de ayuda
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                AppStrings.reorderHelp,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),

        // Lista reordenable de páginas
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pages.length,
            onReorder: _viewModel.reorderPages,
            itemBuilder: (context, index) {
              final page = pages[index];
              return _PageCardItem(
                key: ValueKey(page.id),
                page: page,
                onRotate: () => _viewModel.rotatePage(page.id),
                onFilter: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PageFilterView(
                        page: page,
                        onFilterSelected: (newFilter) {
                          _viewModel.applyFilter(page.id, newFilter);
                        },
                      ),
                    ),
                  );
                },
                onCrop: () async {
                  final corners = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CropPerspectiveView(imagePath: page.originalImagePath),
                    ),
                  );
                  if (corners != null) {
                    _viewModel.cropPage(page.id, corners);
                  }
                },
                onDelete: () => _confirmDeletePage(page),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
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
            // Botón añadir más páginas
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CameraScannerView(
                        repository: widget.repository,
                        shareExportService: widget.shareExportService,
                      ),
                    ),
                  ).then((_) => _viewModel.loadDocument());
                },
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                label: const Text(AppStrings.addPage),
              ),
            ),
            const SizedBox(width: 14),
            // Botón compilar PDF
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _viewModel.pages.isEmpty || _viewModel.isProcessingAction
                    ? null
                    : _handleCompilePdf,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: const Text(AppStrings.generatePdf),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageCardItem extends StatelessWidget {
  final ScannedPageModel page;
  final VoidCallback onRotate;
  final VoidCallback onFilter;
  final VoidCallback onCrop;
  final VoidCallback onDelete;

  const _PageCardItem({
    super.key,
    required this.page,
    required this.onRotate,
    required this.onFilter,
    required this.onCrop,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniatura con insignia de número de página
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 90,
                    height: 125,
                    color: Colors.grey.shade200,
                    child: Image.file(
                      File(page.processedImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Pág. ${page.pageNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Opciones de edición de la página
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro activo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Filtro: ${page.filter.displayName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botones de acción rápida en fila
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.rotate_right_rounded, size: 16),
                        label: const Text('Rotar'),
                        onPressed: onRotate,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Filtro'),
                        onPressed: onFilter,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.crop_rounded, size: 16),
                        label: const Text('Recorte'),
                        onPressed: onCrop,
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Icono de arrastrar para reordenar
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Icon(Icons.drag_handle_rounded, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
