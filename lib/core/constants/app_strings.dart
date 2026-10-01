/// Textos y mensajes del sistema en español
class AppStrings {
  AppStrings._();

  static const String appName = 'Escáner Local';
  static const String appTagline = 'Escaneo de documentos 100% privado y offline';

  // Pantalla principal
  static const String myDocuments = 'Mis Documentos';
  static const String searchHint = 'Buscar documento...';
  static const String noDocumentsTitle = 'Sin documentos guardados';
  static const String noDocumentsDesc = 'Presiona el botón de cámara para digitalizar tu primer documento sin conexión a internet.';
  static const String pagesCount = 'páginas';
  static const String pageCountSingle = 'página';
  static const String scanNewDocument = 'Escanear Documento';
  static const String scanWithMlKit = 'Escáner Inteligente (ML Kit)';
  static const String scanWithCamera = 'Cámara Manual Guiada';

  // Cámara y Captura
  static const String alignDocumentGuide = 'Alinea el documento dentro del marco';
  static const String captureButton = 'Capturar';
  static const String finishScanning = 'Finalizar';
  static const String pagesCaptured = 'capturadas';
  static const String flashAuto = 'Auto';
  static const String flashOn = 'Encendido';
  static const String flashOff = 'Apagado';
  static const String cameraPermissionRequired = 'Se requiere permiso de cámara para escanear documentos.';
  static const String grantPermission = 'Conceder Permiso';

  // Recorte y perspectiva
  static const String cropTitle = 'Ajustar Bordes y Perspectiva';
  static const String cropSubtitle = 'Arrastra las 4 esquinas para encuadrar la página';
  static const String resetCrop = 'Restablecer';
  static const String applyCrop = 'Confirmar Recorte';

  // Editor de documento
  static const String editorTitle = 'Editar Documento';
  static const String addPage = 'Añadir Página';
  static const String rotateRight = 'Rotar 90°';
  static const String applyFilter = 'Filtros';
  static const String deletePage = 'Eliminar';
  static const String reorderHelp = 'Mantén presionada una página para reordenarla';
  static const String generatePdf = 'Generar PDF';
  static const String documentName = 'Nombre del documento';
  static const String enterDocumentName = 'Ingresa el nombre del documento';
  static const String saveChanges = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String deletePageConfirm = '¿Deseas eliminar esta página del documento?';
  static const String deleteDocumentConfirm = '¿Deseas eliminar este documento y todos sus archivos locales?';
  static const String confirmDelete = 'Eliminar';

  // Filtros de imagen
  static const String filterOriginal = 'Original';
  static const String filterBinarized = 'B&N Texto';
  static const String filterBinarizedDesc = 'Alto contraste y fondo blanco limpio';
  static const String filterGrayscale = 'Escala de Grises';
  static const String filterGrayscaleDesc = 'Tonos grises suaves de 8 bits';
  static const String filterMagicColor = 'Color Mejorado';
  static const String filterMagicColorDesc = 'Realce de nitidez, saturación y contraste';
  static const String selectFilter = 'Seleccionar Filtro de Imagen';

  // Exportación y visualización
  static const String pdfViewerTitle = 'Vista Previa de PDF';
  static const String shareDocument = 'Compartir PDF';
  static const String saveToGallery = 'Guardar Imágenes en Galería';
  static const String saveToDownloads = 'Guardar en Descargas';
  static const String printDocument = 'Imprimir';
  static const String shareSuccess = 'Archivo preparado para compartir';
  static const String saveSuccess = 'Archivo guardado exitosamente';
  static const String exportError = 'Error al exportar el archivo local';

  // Privacidad
  static const String offlineBadge = '100% Offline • Datos privados';
}
