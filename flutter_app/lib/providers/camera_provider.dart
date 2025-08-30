import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ocr_service.dart';
import '../models/medicine.dart';

class CameraProvider with ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isCapturing = false;
  File? _capturedImage;
  OCRResult? _ocrResult;
  String? _error;

  // Getters
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get cameras => _cameras;
  int get selectedCameraIndex => _selectedCameraIndex;
  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  File? get capturedImage => _capturedImage;
  OCRResult? get ocrResult => _ocrResult;
  String? get error => _error;

  // Initialize camera
  Future<bool> initializeCamera() async {
    try {
      _setError(null);
      
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _setError('Camera permission is required');
        return false;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('No cameras available');
        return false;
      }

      // Initialize camera controller
      await _initializeCameraController();
      
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to initialize camera: $e');
      return false;
    }
  }

  Future<void> _initializeCameraController() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    notifyListeners();
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCameraController();
  }

  // Capture image
  Future<File?> captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _setError('Camera not initialized');
      return null;
    }

    try {
      _setCapturing(true);
      _setError(null);

      final XFile image = await _cameraController!.takePicture();
      _capturedImage = File(image.path);
      
      notifyListeners();
      return _capturedImage;
    } catch (e) {
      _setError('Failed to capture image: $e');
      return null;
    } finally {
      _setCapturing(false);
    }
  }

  // Process image with OCR
  Future<OCRResult?> processImageWithOCR() async {
    if (_capturedImage == null) {
      _setError('No image captured');
      return null;
    }

    try {
      _setCapturing(true);
      _setError(null);

      final OCRService ocrService = OCRService();
      _ocrResult = await ocrService.processImage(_capturedImage!);
      
      notifyListeners();
      return _ocrResult;
    } catch (e) {
      _setError('OCR processing failed: $e');
      return null;
    } finally {
      _setCapturing(false);
    }
  }

  // Retake photo
  void retakePhoto() {
    _capturedImage = null;
    _ocrResult = null;
    _setError(null);
    notifyListeners();
  }

  // Clear captured image and OCR result
  void clearImage() {
    _capturedImage = null;
    _ocrResult = null;
    _setError(null);
    notifyListeners();
  }

  // Get camera preview size
  Size? getCameraPreviewSize() {
    if (_cameraController?.value.previewSize != null) {
      return Size(
        _cameraController!.value.previewSize!.width,
        _cameraController!.value.previewSize!.height,
      );
    }
    return null;
  }

  // Check if flash is available
  bool get isFlashAvailable {
    return _cameraController?.value.hasFlash ?? false;
  }

  // Toggle flash
  Future<void> toggleFlash() async {
    if (_cameraController == null || !isFlashAvailable) return;

    try {
      final FlashMode currentMode = _cameraController!.value.flashMode;
      FlashMode newMode;

      switch (currentMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        case FlashMode.always:
          newMode = FlashMode.off;
          break;
        default:
          newMode = FlashMode.off;
      }

      await _cameraController!.setFlashMode(newMode);
      notifyListeners();
    } catch (e) {
      _setError('Failed to toggle flash: $e');
    }
  }

  // Get current flash mode
  FlashMode get currentFlashMode {
    return _cameraController?.value.flashMode ?? FlashMode.off;
  }

  // Check if camera is ready
  bool get isCameraReady {
    return _cameraController?.value.isInitialized ?? false;
  }

  // Get camera aspect ratio
  double get cameraAspectRatio {
    if (_cameraController?.value.previewSize != null) {
      return _cameraController!.value.previewSize!.width /
             _cameraController!.value.previewSize!.height;
    }
    return 4 / 3; // Default aspect ratio
  }

  // Private helper methods
  void _setCapturing(bool capturing) {
    _isCapturing = capturing;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
