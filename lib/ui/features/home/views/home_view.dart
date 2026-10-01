import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/document_model.dart';
import '../../../../data/repositories/document_repository.dart';
import '../../../../data/services/scanner_service.dart';
import '../../../../data/services/share_export_service.dart';
import '../../../core_widgets/custom_app_bar.dart';
import '../../../core_widgets/empty_state_view.dart';
import '../../../core_widgets/loading_indicator.dart';
import '../../editor/views/document_editor_view.dart';
import '../../scanner/views/camera_scanner_view.dart';
import '../../viewer/views/pdf_viewer_view.dart';
import '../view_models/home_view_model.dart';

class HomeView extends StatefulWidget {
  final DocumentRepository repository;
  final ScannerService scannerService;
  final ShareExportService shareExportService;

  const HomeView({
    super.key,
    required this.repository,
    required this.scannerService,
    required this.shareExportService,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      repository: widget.repository,
      scannerService: widget.scannerService,
      shareExportService: widget.shareExportService,
    );
    _viewModel.loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Elige el modo de captura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary),
                  ),
                  title: const Text(
                    AppStrings.scanWithMlKit,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Detección automática de bordes y perspectiva en el dispositivo'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final newDoc = await _viewModel.scanWithMlKit();
                    if (newDoc != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentEditorView(
                            documentId: newDoc.id,
                            repository: widget.repository,
                            shareExportService: widget.shareExportService,
                          ),
                        ),
                      ).then((_) => _viewModel.loadDocuments());
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: AppColors.secondary),
                  ),
                  title: const Text(
                    AppStrings.scanWithCamera,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Cámara en vivo con guías de encuadre y recorte manual de 4 esquinas'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraScannerView(
                          repository: widget.repository,
                          shareExportService: widget.shareExportService,
                        ),
                      ),
                    ).then((_) => _viewModel.loadDocuments());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: AppStrings.myDocuments,
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const LoadingIndicator(message: 'Cargando documentos locales...');
          }

          if (_viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _viewModel.loadDocuments,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_viewModel.documents.isEmpty && _searchController.text.isEmpty) {
            return EmptyStateView(onScanPressed: _showScanOptions);
          }

          return Column(
            children: [
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _viewModel.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _viewModel.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Lista de documentos
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _viewModel.loadDocuments,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _viewModel.documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = _viewModel.documents[index];
                      return _DocumentCard(
                        document: doc,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerView(
                                documentId: doc.id,
                                repository: widget.repository,
                                shareExportService: widget.shareExportService,
                              ),
                            ),
                          ).then((_) => _viewModel.loadDocuments());
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DocumentEditorView(
                                documentId: doc.id,
                                repository: widget.repository,
                                shareExportService: widget.shareExportService,
                              ),
                            ),
                          ).then((_) => _viewModel.loadDocuments());
                        },
                        onShare: () => _viewModel.shareDocument(doc),
                        onDelete: () => _confirmDelete(doc),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScanOptions,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Escanear'),
      ),
    );
  }

  void _confirmDelete(DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente "${doc.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _viewModel.deleteDocument(doc.id);
            },
            child: const Text(AppStrings.confirmDelete),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy • HH:mm');
    final formattedDate = dateFormat.format(document.updatedAt);
    final pageText = document.pageCount == 1 ? '1 página' : '${document.pageCount} páginas';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Miniatura
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 65,
                  height: 85,
                  color: Colors.grey.shade100,
                  child: document.thumbnailPath != null && File(document.thumbnailPath!).existsSync()
                      ? Image.file(
                          File(document.thumbnailPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                        )
                      : const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 32),
                ),
              ),
              const SizedBox(width: 14),

              // Información del documento
              Expanded(
                child: Column(
                  crossContent: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pageText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botones de acción rápida
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 22, color: Colors.blueGrey),
                    tooltip: 'Editar páginas',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 22, color: AppColors.primary),
                    tooltip: 'Compartir PDF',
                    onPressed: onShare,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.redAccent),
                    tooltip: 'Eliminar',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
