import 'package:flutter/material.dart';

import '../../app.dart';
import '../../l10n/scanvibe_localizations.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key, required this.state});

  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('scan'))),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            final pendingOcrCount = state.documents.fold<int>(
              0,
              (sum, doc) =>
                  sum + doc.pages.where((p) => p.ocrStatus.canRun).length,
            );
            final totalDocuments = state.documents.length;
            final totalPages = state.documents.fold<int>(
              0,
              (sum, doc) => sum + doc.pages.length,
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        strings.text('scanHeaderTitle'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.text('scanHeaderSubtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (state.captureError != null)
                        Card(
                          color: theme.colorScheme.errorContainer,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    strings.text(state.captureError!),
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: state.clearCaptureError,
                                  color: theme.colorScheme.error,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Camera Unavailable Notice
                      if (!state.isCameraAvailable)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  strings.text('cameraUnavailableHelp'),
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Interactive Animated Viewport
                      const SizedBox(height: 240, child: ScannerViewport()),
                      const SizedBox(height: 20),

                      // Recognition Language Selector
                      DropdownButtonFormField<String>(
                        initialValue: state.ocrLanguage,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: strings.text('ocrLanguageSelect'),
                          prefixIcon: const Icon(Icons.translate),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'latin',
                            child: Text(
                              strings.text('ocrLangLatin'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'devanagari',
                            child: Text(
                              strings.text('ocrLangDevanagari'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'chinese',
                            child: Text(
                              strings.text('ocrLangChinese'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'japanese',
                            child: Text(
                              strings.text('ocrLangJapanese'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'korean',
                            child: Text(
                              strings.text('ocrLangKorean'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            state.setOcrLanguage(val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // Statistics Row
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                Icons.folder_open_outlined,
                                '$totalDocuments',
                                strings.text('documents'),
                              ),
                              _buildStatItem(
                                context,
                                Icons.description_outlined,
                                '$totalPages',
                                strings.text(totalPages == 1 ? 'page' : 'pages'),
                              ),
                              _buildStatItem(
                                context,
                                Icons.hourglass_empty_outlined,
                                '$pendingOcrCount',
                                strings.text(
                                  pendingOcrCount == 1
                                      ? 'pendingPage'
                                      : 'pendingPages',
                                ),
                                highlight: pendingOcrCount > 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buttons Block
                      if (state.isCameraAvailable) ...[
                        FilledButton.icon(
                          onPressed: state.createDocumentFromCamera,
                          icon: const Icon(Icons.photo_camera),
                          label: Text(strings.text('camera')),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: state.importDocumentFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(strings.text('gallery')),
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.photo_camera_front_outlined),
                          label: Text(
                            '${strings.text('camera')} (${strings.text('failed')})',
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: state.importDocumentFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: Text(strings.text('gallery')),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Recognition Button
                      OutlinedButton.icon(
                        onPressed:
                            state.isBusy || pendingOcrCount == 0
                                ? null
                                : state.processQueuedPages,
                        icon: state.isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cloud_sync_outlined),
                        label: Text(strings.text('processQueue')),
                        style:
                            pendingOcrCount > 0 && !state.isBusy
                                ? OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 1.5,
                                    ),
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.05),
                                  )
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String count,
    String label, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final color =
        highlight
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          count,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ScannerViewport extends StatefulWidget {
  const ScannerViewport({super.key});

  @override
  State<ScannerViewport> createState() => _ScannerViewportState();
}

class _ScannerViewportState extends State<ScannerViewport>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        const padding = 24.0;
        final laserTravelHeight = height - (padding * 2);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.document_scanner_outlined,
                    size: 110,
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                // Corner brackets
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(padding),
                    child: CustomPaint(
                      painter: ScannerCornersPainter(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                // Laser line animation
                if (laserTravelHeight > 0)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Positioned(
                        top: padding + laserTravelHeight * _controller.value,
                        left: padding,
                        right: padding,
                        child: child!,
                      );
                    },
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.01),
                            theme.colorScheme.primary,
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.01),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2.5,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ScannerCornersPainter extends CustomPainter {
  ScannerCornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
