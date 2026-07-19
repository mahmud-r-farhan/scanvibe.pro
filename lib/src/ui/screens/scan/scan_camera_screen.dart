import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../enums.dart';
import '../../../providers/documents_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/camera_service.dart';
import '../../../theme/app_colors.dart';

class ScanCameraScreen extends ConsumerStatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  ConsumerState<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends ConsumerState<ScanCameraScreen>
    with SingleTickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isCameraInitialized = false;
  bool _isInitializing = false;
  bool _hasPermission = false;
  bool _showPermissionDenied = false;
  bool _isCapturing = false;
  bool _isFlashOn = false;
  bool _isUsingFrontCamera = false;
  bool _autoCaptureEnabled = true;
  ScanMode _selectedScanMode = ScanMode.document;
  String _selectedOcrLanguage = 'latin';

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  String? _errorMessage;
  int _captureCount = 0;
  String? _currentDocumentId;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
    _laserController.repeat(reverse: true);

    _loadSettings();
    _initializeCamera();
  }

  void _loadSettings() {
    final settings = ref.read(settingsProvider);
    _autoCaptureEnabled = settings.autoCapture;
    _selectedOcrLanguage = settings.ocrLanguage;
    final defaultMode = settings.defaultScanMode;
    _selectedScanMode = ScanMode.values.firstWhere(
      (m) => m.name == defaultMode,
      orElse: () => ScanMode.document,
    );
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _hasPermission = false;
          _showPermissionDenied = true;
          _isInitializing = false;
        });
        return;
      }

      _hasPermission = true;

      if (_cameraService.isInitialized) {
        await _cameraService.dispose();
      }

      await _cameraService.initialize(
        resolution: ResolutionPreset.high,
        enableAudio: false,
      );

      setState(() {
        _isCameraInitialized = true;
        _isInitializing = false;
        _errorMessage = null;
      });
    } on CameraException catch (e) {
      setState(() {
        _isCameraInitialized = false;
        _isInitializing = false;
        _errorMessage = 'Camera error: ${e.description}';
      });
    } catch (e) {
      setState(() {
        _isCameraInitialized = false;
        _isInitializing = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (!_cameraService.hasMultipleCameras) return;

    setState(() {
      _isCameraInitialized = false;
    });

    try {
      await _cameraService.switchCamera();
      setState(() {
        _isCameraInitialized = true;
        _isUsingFrontCamera = !_isUsingFrontCamera;
      });
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Failed to switch camera: ${e.description}';
      });
    }
  }

  Future<void> _toggleFlash() async {
    final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
    try {
      await _cameraService.setFlashMode(newMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } on CameraException catch (e) {
      setState(() {
        _errorMessage = 'Flash error: ${e.description}';
      });
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing || !_isCameraInitialized) return;

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      HapticFeedback.mediumImpact();

      if (_isFlashOn) {
        await _cameraService.setFlashMode(FlashMode.off);
      }

      final imagePath = await _cameraService.takePicture();

      if (_isFlashOn) {
        await _cameraService.setFlashMode(FlashMode.torch);
      }

      _captureCount++;

      if (_currentDocumentId == null) {
        final docId = await ref.read(documentsProvider.notifier).createDocument(
              scanMode: _selectedScanMode.name,
            );
        _currentDocumentId = docId;
      }

      await ref.read(documentsProvider.notifier).addPageToDocument(
            documentId: _currentDocumentId!,
            imagePath: imagePath,
            filterType: _selectedScanMode == ScanMode.document
                ? 'auto_enhance'
                : _selectedScanMode == ScanMode.whiteboard
                    ? 'clean'
                    : _selectedScanMode == ScanMode.receipt
                        ? 'black_white'
                        : 'auto_enhance',
          );

      setState(() {
        _isCapturing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page $_captureCount captured successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: _captureCount > 1
                ? SnackBarAction(
                    label: 'Done',
                    textColor: Colors.white,
                    onPressed: _finishCapture,
                  )
                : null,
          ),
        );
      }
    } on CameraException catch (e) {
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Capture failed: ${e.description}';
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Capture failed: $e';
      });
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );

      if (image == null) return;

      setState(() {
        _errorMessage = null;
      });

      if (_currentDocumentId == null) {
        final docId = await ref.read(documentsProvider.notifier).createDocument(
              scanMode: _selectedScanMode.name,
            );
        _currentDocumentId = docId;
      }

      await ref.read(documentsProvider.notifier).addPageToDocument(
            documentId: _currentDocumentId!,
            imagePath: image.path,
            filterType: 'auto_enhance',
          );

      _captureCount++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image imported successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to import image: $e';
      });
    }
  }

  void _finishCapture() {
    if (_currentDocumentId != null && _captureCount > 0) {
      context.push('/document/$_currentDocumentId');
    } else {
      context.pop();
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(theme),
          _buildScannerOverlay(theme),
          _buildTopBar(theme),
          _buildScanModePicker(theme),
          _buildBottomControls(theme),
          if (_errorMessage != null) _buildErrorBanner(theme),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(ThemeData theme) {
    if (_showPermissionDenied) {
      return _buildPermissionDeniedView(theme);
    }

    if (!_isCameraInitialized || _cameraService.controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return CameraPreview(_cameraService.controller!);
  }

  Widget _buildPermissionDeniedView(ThemeData theme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Access Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'ScanVibe Pro needs camera access to scan documents. Please grant permission in your device settings.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                  final opened = await openAppSettings();
                  if (opened) {
                    await _initializeCamera();
                  }
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _finishCapture,
                child: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(ThemeData theme) {
    if (!_isCameraInitialized) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scanAreaSize = width * 0.85;
        final scanAreaHeight = scanAreaSize * 1.414;
        final maxScanHeight = height * 0.55;
        final effectiveHeight =
            scanAreaHeight > maxScanHeight ? maxScanHeight : scanAreaHeight;
        final effectiveWidth = effectiveHeight / 1.414;

        final left = (width - effectiveWidth) / 2;
        final top = (height - effectiveHeight) / 2 - 40;

        return Stack(
          children: [
            // Dim overlay
            CustomPaint(
              size: Size(width, height),
              painter: _ScannerDimOverlayPainter(
                scanRect: Rect.fromLTWH(left, top, effectiveWidth, effectiveHeight),
              ),
            ),

            // Corner brackets
            Positioned(
              left: left,
              top: top,
              width: effectiveWidth,
              height: effectiveHeight,
              child: CustomPaint(
                painter: _ScannerCornersPainter(
                  color: AppColors.scannerCorner,
                ),
              ),
            ),

            // Animated laser line
            AnimatedBuilder(
              animation: _laserAnimation,
              builder: (context, child) {
                final laserY = top + effectiveHeight * _laserAnimation.value;
                return Positioned(
                  top: laserY,
                  left: left + 8,
                  right: width - left - effectiveWidth + 8,
                  child: child!,
                );
              },
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.scannerLaser.withValues(alpha: 0.4),
                      AppColors.scannerLaser,
                      AppColors.scannerLaser,
                      AppColors.scannerLaser.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.15, 0.35, 0.65, 0.85, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.scannerLaser.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Scan mode hint text
            Positioned(
              top: top + effectiveHeight + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedScanMode.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _selectedScanMode.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                if (_captureCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_captureCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_captureCount > 0)
                  const SizedBox(width: 4)
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanModePicker(ThemeData theme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: ScanMode.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final mode = ScanMode.values[index];
            final isSelected = mode == _selectedScanMode;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedScanMode = mode;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryLight
                      : Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconForScanMode(mode),
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auto-capture & OCR language row
                Row(
                  children: [
                    _buildAutoCaptureToggle(),
                    const Spacer(),
                    _buildOcrLanguageChip(),
                    const Spacer(),
                    _buildDoneButton(),
                  ],
                ),
                const SizedBox(height: 20),

                // Main controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    _buildCircularButton(
                      onPressed: _importFromGallery,
                      icon: Icons.photo_library_outlined,
                      tooltip: 'Gallery',
                    ),

                    // Shutter button
                    _buildShutterButton(),

                    // Camera switch button
                    _buildCircularButton(
                      onPressed: _cameraService.hasMultipleCameras
                          ? _switchCamera
                          : null,
                      icon: Icons.cameraswitch_outlined,
                      tooltip: 'Switch Camera',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Flash toggle & capture count
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFlashButton(),
                    if (_captureCount > 0) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _finishCapture,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppColors.scannerLaser,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_captureCount captured',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoCaptureToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _autoCaptureEnabled = !_autoCaptureEnabled;
        });
        ref
            .read(settingsProvider.notifier)
            .setAutoCapture(_autoCaptureEnabled);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _autoCaptureEnabled
              ? AppColors.primaryLight.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _autoCaptureEnabled ? Icons.autorenew : Icons.touch_app_outlined,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              _autoCaptureEnabled ? 'Auto' : 'Manual',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrLanguageChip() {
    final language = ScanLanguage.values.firstWhere(
      (l) => l.code == _selectedOcrLanguage,
      orElse: () => ScanLanguage.latin,
    );

    return GestureDetector(
      onTap: _showLanguagePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.translate,
              size: 14,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              language.displayName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    if (_captureCount == 0) return const SizedBox(width: 80);

    return GestureDetector(
      onTap: _finishCapture,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCapturing
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white,
            gradient: _isCapturing
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFE8E8E8)],
                  ),
          ),
          child: _isCapturing
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryLight,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFlashButton() {
    return GestureDetector(
      onTap: _toggleFlash,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isFlashOn
              ? AppColors.warning.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _isFlashOn ? Icons.flash_on : Icons.flash_off,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: onPressed != null
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: onPressed != null ? Colors.white : Colors.white38,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 110,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _errorMessage = null),
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'OCR Language',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...ScanLanguage.values.map(
                  (lang) => ListTile(
                    leading: Icon(
                      lang == _selectedOcrLanguage
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: lang == _selectedOcrLanguage
                          ? AppColors.primaryLight
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(lang.displayName),
                    subtitle: Text(
                      'Code: ${lang.code}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedOcrLanguage = lang.code;
                      });
                      ref
                          .read(settingsProvider.notifier)
                          .setOcrLanguage(lang.code);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForScanMode(ScanMode mode) {
    return switch (mode) {
      ScanMode.document => Icons.description_outlined,
      ScanMode.idCard => Icons.badge_outlined,
      ScanMode.whiteboard => Icons.dashboard_outlined,
      ScanMode.qrCode => Icons.qr_code_scanner,
      ScanMode.book => Icons.menu_book_outlined,
      ScanMode.receipt => Icons.receipt_long_outlined,
    };
  }
}

class _ScannerDimOverlayPainter extends CustomPainter {
  _ScannerDimOverlayPainter({required this.scanRect});

  final Rect scanRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = AppColors.scannerOverlay;

    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, scanRect.top),
      overlayPaint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        scanRect.bottom,
        size.width,
        size.height - scanRect.bottom,
      ),
      overlayPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height),
      overlayPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(
        scanRect.right,
        scanRect.top,
        size.width - scanRect.right,
        scanRect.height,
      ),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerDimOverlayPainter oldDelegate) {
    return oldDelegate.scanRect != scanRect;
  }
}

class _ScannerCornersPainter extends CustomPainter {
  _ScannerCornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const radius = 4.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..quadraticBezierTo(0, size.height, radius, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - radius,
        )
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
