import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/models/document_model.dart';
import '../../../../data/repositories/document_repository.dart';

/// ViewModel para la captura de fotos con la cámara en vivo y gestión de ráfagas multi-página
class ScannerViewModel extends ChangeNotifier {
  final DocumentRepository _repository;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _hasPermission = false;
  FlashMode _currentFlashMode = FlashMode.off;
  final List<String> _capturedImages = [];
  String? _errorMessage;

  ScannerViewModel({required DocumentRepository repository}) : _repository = repository;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  bool get hasPermission => _hasPermission;
  FlashMode get currentFlashMode => _currentFlashMode;
  List<String> get capturedImages => List.unmodifiable(_capturedImages);
  int get pageCount => _capturedImages.length;
  String? get errorMessage => _errorMessage;

  /// Solicita permisos y prepara el controlador de cámara
  Future<void> initCamera() async {
    _errorMessage = null;
    notifyListeners();

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _hasPermission = false;
      _errorMessage = 'Se requiere el permiso de cámara para escanear.';
      notifyListeners();
      return;
    }

    _hasPermission = true;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _errorMessage = 'No se encontraron cámaras disponibles en el dispositivo.';
        notifyListeners();
        return;
      }

      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      _errorMessage = 'Error al inicializar la cámara: $e';
      notifyListeners();
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    final prevController = _cameraController;
    if (prevController != null) {
      await prevController.dispose();
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_currentFlashMode);
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Error al configurar el visor de cámara: $e';
      _isInitialized = false;
    }

    notifyListeners();
  }

  /// Alterna el modo del flash entre apagado, automático y antorcha
  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      FlashMode nextMode;
      switch (_currentFlashMode) {
        case FlashMode.off:
          nextMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          nextMode = FlashMode.torch;
          break;
        default:
          nextMode = FlashMode.off;
          break;
      }

      await _cameraController!.setFlashMode(nextMode);
      _currentFlashMode = nextMode;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cambiar flash: $e');
    }
  }

  /// Dispara y captura una nueva página
  Future<String?> capturePage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isCapturing) {
      return null;
    }

    _isCapturing = true;
    notifyListeners();

    try {
      final XFile photo = await _cameraController!.takePicture();
      _capturedImages.add(photo.path);
      return photo.path;
    } catch (e) {
      _errorMessage = 'Error al capturar la imagen: $e';
      return null;
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }

  /// Elimina una captura de la cola actual
  void removeLastCapture() {
    if (_capturedImages.isNotEmpty) {
      final last = _capturedImages.removeLast();
      try {
        final f = File(last);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
      notifyListeners();
    }
  }

  /// Finaliza el proceso de captura y crea el documento en la base de datos
  Future<DocumentModel?> finishScanning({String? customTitle}) async {
    if (_capturedImages.isEmpty) return null;

    try {
      final doc = await _repository.createDocumentFromRawImages(
        rawImagePaths: _capturedImages,
        title: customTitle,
      );
      return doc;
    } catch (e) {
      _errorMessage = 'Error al guardar el documento escaneado: $e';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
