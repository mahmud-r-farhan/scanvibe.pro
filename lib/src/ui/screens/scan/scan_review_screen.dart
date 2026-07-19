import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;

import '../../../enums.dart';
import '../../../providers/documents_provider.dart';
import '../../../services/image_processing_service.dart';
import '../../../theme/app_colors.dart';

class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.imagePath,
    required this.scanMode,
  });

  final String imagePath;
  final String scanMode;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late String _currentImagePath;
  FilterType _selectedFilter = FilterType.autoEnhance;
  bool _isProcessing = false;
  bool _hasModified = false;
  int _rotationDegrees = 0;

  late final ImageProcessingService _imageService;
  late final List<_FilterOption> _filters;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _imageService = ImageProcessingService();
    _filters = [
      _FilterOption(type: FilterType.autoEnhance, label: 'Auto'),
      _FilterOption(type: FilterType.blackWhite, label: 'B&W'),
      _FilterOption(type: FilterType.grayscale, label: 'Gray'),
      _FilterOption(type: FilterType.magicColor, label: 'Magic'),
      _FilterOption(type: FilterType.sharpen, label: 'Sharp'),
      _FilterOption(type: FilterType.clean, label: 'Clean'),
    ];
  }

  Future<void> _applyFilter(FilterType filter) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedFilter = filter;
    });

    try {
      final processedPath = await _imageService.processImage(
        inputPath: widget.imagePath,
        filter: filter,
      );
      if (mounted) {
        setState(() {
          _currentImagePath = processedPath;
          _hasModified = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rotateImage(int degrees) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await File(_currentImagePath).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      image = img.copyRotate(image, angle: degrees);

      final outPath = _currentImagePath.replaceAll(
        '.jpg',
        '_rotated_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));

      if (mounted) {
        setState(() {
          _currentImagePath = outPath;
          _rotationDegrees = (_rotationDegrees + degrees) % 360;
          _hasModified = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rotation failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _retake() {
    context.pop();
  }

  void _save() {
    context.pop({'imagePath': _currentImagePath, 'saved': true});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildImagePreview(theme),
          _buildTopBar(theme),
          _buildFilterCarousel(theme),
          _buildBottomBar(theme),
          if (_isProcessing) _buildLoadingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.file(
            File(_currentImagePath),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                const Expanded(
                  child: Center(
                    child: Text(
                      'Review Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopBarButton(
                      icon: Icons.rotate_left,
                      tooltip: 'Rotate Left',
                      onPressed: _isProcessing ? null : () => _rotateImage(-90),
                    ),
                    const SizedBox(width: 4),
                    _buildTopBarButton(
                      icon: Icons.rotate_right,
                      tooltip: 'Rotate Right',
                      onPressed: _isProcessing ? null : () => _rotateImage(90),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: onPressed != null
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: onPressed != null ? Colors.white : Colors.white38,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCarousel(ThemeData theme) {
    return Positioned(
      bottom: 88,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4),
              child: Text(
                'Filter',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter.type == _selectedFilter;
                  final filterColor =
                      AppColors.filterColors[filter.type.name] ??
                          AppColors.primaryLight;

                  return GestureDetector(
                    onTap: () => _applyFilter(filter.type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? filterColor.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? filterColor
                              : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: filterColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getFilterIcon(filter.type),
                            size: 22,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            filter.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Retake button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Retake'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Save button
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Applying filter...',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFilterIcon(FilterType type) {
    return switch (type) {
      FilterType.autoEnhance => Icons.auto_awesome,
      FilterType.blackWhite => Icons.contrast,
      FilterType.grayscale => Icons.gradient,
      FilterType.magicColor => Icons.palette_outlined,
      FilterType.sharpen => Icons.center_focus_strong,
      FilterType.clean => Icons.cleaning_services_outlined,
    };
  }
}

class _FilterOption {
  const _FilterOption({required this.type, required this.label});
  final FilterType type;
  final String label;
}
