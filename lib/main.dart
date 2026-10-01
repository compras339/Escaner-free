import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EscanerSimpleApp());
}

/// Aplicación de Escáner en un Único Archivo (Simple y Modular)
class EscanerSimpleApp extends StatelessWidget {
  const EscanerSimpleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F766E), // Verde esmeralda
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const EscanerHomePage(),
    );
  }
}

class EscanerHomePage extends StatefulWidget {
  const EscanerHomePage({super.key});

  @override
  State<EscanerHomePage> createState() => _EscanerHomePageState();
}

class _EscanerHomePageState extends State<EscanerHomePage> {
  // Lista de rutas de las páginas escaneadas del documento actual
  final List<String> _paginas = [];
  bool _procesando = false;

  /// 1. Escaneo inteligente usando el hardware local (Google ML Kit on-device)
  /// Detección automática de bordes, corrección de perspectiva y limpieza en el móvil
  Future<void> _escanearDocumento() async {
    setState(() => _procesando = true);
    try {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.full,
          pageLimit: 50,
          isGalleryImportAllowed: true,
        ),
      );

      final resultado = await scanner.scanDocument();
      await scanner.close();

      if (resultado.images != null && resultado.images!.isNotEmpty) {
        setState(() {
          _paginas.addAll(resultado.images!);
        });
      }
    } catch (e) {
      _mostrarMensaje('Error o cancelación al escanear: $e');
    } finally {
      setState(() => _procesando = false);
    }
  }

  /// 2. Rotar una página 90 grados de forma local
  Future<void> _rotarPagina(int index) async {
    setState(() => _procesando = true);
    try {
      final path = _paginas[index];
      final bytes = await File(path).readAsBytes();
      img.Image? imagen = img.decodeImage(bytes);

      if (imagen != null) {
        imagen = img.copyRotate(imagen, angle: 90);
        final nuevoPath = '${path}_rot.jpg';
        await File(nuevoPath).writeAsBytes(img.encodeJpg(imagen, quality: 90));

        setState(() {
          _paginas[index] = nuevoPath;
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al rotar página: $e');
    } finally {
      setState(() => _procesando = false);
    }
  }

  /// 3. Aplicar filtro blanco y negro (binarización para texto limpio)
  Future<void> _aplicarFiltroTexto(int index) async {
    setState(() => _procesando = true);
    try {
      final path = _paginas[index];
      final bytes = await File(path).readAsBytes();
      img.Image? imagen = img.decodeImage(bytes);

      if (imagen != null) {
        imagen = img.grayscale(imagen);
        // Umbral de alto contraste para eliminar sombras y fondo grisáceo
        for (int y = 0; y < imagen.height; y++) {
          for (int x = 0; x < imagen.width; x++) {
            final p = imagen.getPixel(x, y);
            final val = p.r > 130 ? 255 : 0;
            imagen.setPixelRgba(x, y, val, val, val, 255);
          }
        }

        final nuevoPath = '${path}_bn.jpg';
        await File(nuevoPath).writeAsBytes(img.encodeJpg(imagen, quality: 90));
        setState(() {
          _paginas[index] = nuevoPath;
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al aplicar filtro: $e');
    } finally {
      setState(() => _procesando = false);
    }
  }

  /// 4. Compilar las páginas en un archivo PDF local y abrir la hoja de compartir nativa
  Future<void> _generarYCompartirPdf() async {
    if (_paginas.isEmpty) return;

    setState(() => _procesando = true);
    try {
      final pdf = pw.Document();

      for (final ruta in _paginas) {
        final imagenBytes = await File(ruta).readAsBytes();
        final pdfImagen = pw.MemoryImage(imagenBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Image(pdfImagen, fit: pw.BoxFit.contain),
              ),
            ),
          ),
        );
      }

      // Guardar PDF en almacenamiento temporal seguro
      final tempDir = await getTemporaryDirectory();
      final fecha = DateTime.now().millisecondsSinceEpoch;
      final pdfFile = File('${tempDir.path}/Documento_$fecha.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      // Abrir hoja nativa de compartir (WhatsApp, Drive, Gmail, etc.)
      await Share.shareXFiles(
        [XFile(pdfFile.path, mimeType: 'application/pdf')],
        text: 'Documento escaneado offline',
      );
    } catch (e) {
      _mostrarMensaje('Error al generar PDF: $e');
    } finally {
      setState(() => _procesando = false);
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner Local (100% Offline)'),
        centerTitle: true,
        actions: [
          if (_paginas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Limpiar todo',
              onPressed: () => setState(() => _paginas.clear()),
            ),
        ],
      ),
      body: _procesando
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F766E)),
                  SizedBox(height: 16),
                  Text('Procesando en el dispositivo...'),
                ],
              ),
            )
          : _paginas.isEmpty
              ? _buildPantallaVacia()
              : _buildListaPaginas(),
      bottomNavigationBar: _paginas.isNotEmpty ? _buildBarraInferior() : null,
      floatingActionButton: _paginas.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _escanearDocumento,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Escanear'),
            )
          : null,
    );
  }

  Widget _buildPantallaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.document_scanner_rounded, size: 72, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ningún documento escaneado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca el botón para abrir la cámara y escanear páginas con detección automática de esquinas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaPaginas() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paginas.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _paginas.removeAt(oldIndex);
          _paginas.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final path = _paginas[index];
        return Card(
          key: ValueKey(path),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(path),
                    width: 70,
                    height: 95,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Página ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _rotarPagina(index),
                            icon: const Icon(Icons.rotate_right_rounded, size: 16),
                            label: const Text('Rotar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _aplicarFiltroTexto(index),
                            icon: const Icon(Icons.contrast_rounded, size: 16),
                            label: const Text('B&N'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => setState(() => _paginas.removeAt(index)),
                ),
                const Icon(Icons.drag_handle_rounded, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarraInferior() {
    return SafeArea(
      child: Container(
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _escanearDocumento,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Añadir Página'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
                onPressed: _generarYCompartirPdf,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Compartir PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
