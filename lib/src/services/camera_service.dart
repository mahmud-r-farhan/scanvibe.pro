import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isInitialized = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get hasMultipleCameras => _cameras.length > 1;
  CameraDescription? get currentCamera =>
      _cameras.isNotEmpty ? _cameras[_currentCameraIndex] : null;

  Future<void> initialize({
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No cameras available');
      }

      await _initCamera(_cameras[_currentCameraIndex], resolution, enableAudio);
    } catch (e) {
      if (e is CameraException) rethrow;
      throw CameraException('init_failed', 'Failed to initialize camera: $e');
    }
  }

  Future<void> _initCamera(
    CameraDescription camera,
    ResolutionPreset resolution,
    bool enableAudio,
  ) async {
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      resolution,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  Future<void> switchCamera({
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    if (_cameras.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initCamera(
      _cameras[_currentCameraIndex],
      resolution,
      enableAudio,
    );
  }

  Future<String> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }

    if (_controller!.value.isTakingPicture) {
      throw CameraException('already_taking', 'Already taking a picture');
    }

    final xFile = await _controller!.takePicture();

    // Copy to app directory for permanent storage
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(appDir.path, 'scans'));
    if (!scansDir.existsSync()) {
      await scansDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(scansDir.path, 'scan_$timestamp.jpg');

    await File(xFile.path).copy(outputPath);
    await File(xFile.path).delete();

    return outputPath;
  }

  Future<void> setFlashMode(FlashMode mode) async {
    await _controller?.setFlashMode(mode);
  }

  Future<void> setFocusMode(FocusMode mode) async {
    await _controller?.setFocusMode(mode);
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    await _controller?.setExposureMode(mode);
  }

  Future<void> setZoomLevel(double zoom) async {
    final minZoom = await _controller!.getMinZoomLevel();
    final maxZoom = await _controller!.getMaxZoomLevel();
    final clampedZoom = zoom.clamp(minZoom, maxZoom);
    await _controller!.setZoomLevel(clampedZoom);
  }

  Future<void> setFocusPoint(Offset point) async {
    await _controller?.setFocusPoint(point);
  }

  Future<void> setExposurePoint(Offset point) async {
    await _controller?.setExposurePoint(point);
  }

  Stream<CameraImage>? get imageStream => _controller?.imageStream;

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

class CameraException implements Exception {
  const CameraException(this.code, this.description);
  final String code;
  final String description;

  @override
  String toString() => 'CameraException($code): $description';
}
