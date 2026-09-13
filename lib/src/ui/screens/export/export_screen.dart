import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../enums.dart';
import '../../../providers/documents_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../theme/app_colors.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  double _imageQuality = 0.92;
  bool _isExporting = false;
  bool _shareAfterExport = true;

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentsProvider);
    final theme = Theme.of(context);

    final docWithPages = docsState.getDocumentById(widget.documentId);
    if (docWithPages == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Export Document'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                docWithPages.document.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${docWithPages.pages.length} pages',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Format Selection
                  Text(
                    'Export Format',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ExportFormat.values.map((format) {
                      final isSelected = _selectedFormat == format;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFormat = format),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getFormatIcon(format),
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  format.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? theme.colorScheme.primary : null,
                                  ),
                                ),
                                Text(
                                  format.extension,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Quality Settings
                  Text(
                    'Image Quality',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _imageQuality,
                          min: 0.5,
                          max: 1.0,
                          divisions: 10,
                          label: '${(_imageQuality * 100).toInt()}%',
                          onChanged: (value) => setState(() => _imageQuality = value),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${(_imageQuality * 100).toInt()}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lower file size',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Higher quality',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Share after export
                  SwitchListTile(
                    title: const Text('Share after export'),
                    subtitle: const Text('Open share sheet when export completes'),
                    value: _shareAfterExport,
                    onChanged: (value) => setState(() => _shareAfterExport = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          // Print & Export Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _printDocument,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _exportDocument,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_isExporting ? 'Exporting...' : 'Export Document'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    return switch (format) {
      ExportFormat.pdf => Icons.picture_as_pdf_rounded,
      ExportFormat.jpeg => Icons.image_rounded,
      ExportFormat.txt => Icons.text_snippet_rounded,
    };
  }

  Future<void> _printDocument() async {
    final docsState = ref.read(documentsProvider);
    final docWithPages = docsState.getDocumentById(widget.documentId);
    if (docWithPages == null) return;

    final pdfPath = await _exportAsPdf(docWithPages);
    if (File(pdfPath).existsSync()) {
      final bytes = await File(pdfPath).readAsBytes();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: docWithPages.document.title,
      );
    }
  }

  String _sanitizeFilename(String title) {
    final clean = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return clean.isEmpty ? 'ScanDocument' : clean;
  }

  Future<void> _exportDocument() async {
    setState(() => _isExporting = true);

    try {
      final docsState = ref.read(documentsProvider);
      final docWithPages = docsState.getDocumentById(widget.documentId);
      if (docWithPages == null) return;

      String exportedPath = '';

      if (_selectedFormat == ExportFormat.pdf) {
        exportedPath = await _exportAsPdf(docWithPages);
      } else if (_selectedFormat == ExportFormat.txt) {
        exportedPath = await _exportAsTxt(docWithPages);
      } else {
        exportedPath = await _exportAsJpeg(docWithPages);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document exported as ${_selectedFormat.displayName}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (_shareAfterExport && exportedPath.isNotEmpty) {
          await Share.shareXFiles(
            [XFile(exportedPath)],
            subject: docWithPages.document.title,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<String> _exportAsPdf(DocumentWithPages docWithPages) async {
    final pdf = pw.Document();
    final settings = ref.read(settingsProvider);
    final includeWatermark = settings.shouldIncludeWatermark;

    // Pre-load and compress all image bytes according to user-selected quality
    final imageBytesList = <String, pw.MemoryImage>{};
    for (final page in docWithPages.pages) {
      if (page.imagePath.isNotEmpty && File(page.imagePath).existsSync()) {
        try {
          final originalBytes = await File(page.imagePath).readAsBytes();
          if (_imageQuality < 0.98) {
            final decoded = img.decodeImage(originalBytes);
            if (decoded != null) {
              final compressed = img.encodeJpg(
                decoded,
                quality: (_imageQuality * 100).toInt().clamp(40, 100),
              );
              imageBytesList[page.imagePath] = pw.MemoryImage(compressed);
              continue;
            }
          }
          imageBytesList[page.imagePath] = pw.MemoryImage(originalBytes);
        } catch (_) {}
      }
    }

    for (var i = 0; i < docWithPages.pages.length; i++) {
      final page = docWithPages.pages[i];
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (page.imagePath.isNotEmpty && imageBytesList.containsKey(page.imagePath))
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(
                      imageBytesList[page.imagePath]!,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              if (page.extractedText?.trim().isNotEmpty == true)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8),
                  child: pw.Text(
                    page.extractedText!.trim(),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              if (includeWatermark) ...[
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Scanned with ScanVibe Pro - Page ${i + 1}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final sanitized = _sanitizeFilename(docWithPages.document.title);
    final pdfBytes = await pdf.save();

    final docsDir = await getApplicationDocumentsDirectory();
    final exportFile = File(p.join(docsDir.path, '$sanitized.pdf'));
    await exportFile.writeAsBytes(pdfBytes);

    return exportFile.path;
  }

  Future<String> _exportAsTxt(DocumentWithPages docWithPages) async {
    final text = docWithPages.combinedText.isNotEmpty
        ? docWithPages.combinedText
        : 'No extracted text available for ${docWithPages.document.title}.';
    final sanitized = _sanitizeFilename(docWithPages.document.title);
    final tempDir = Directory.systemTemp;
    final file = File(p.join(tempDir.path, '$sanitized.txt'));
    await file.writeAsString(text);
    return file.path;
  }

  Future<String> _exportAsJpeg(DocumentWithPages docWithPages) async {
    for (final page in docWithPages.pages) {
      if (page.imagePath.isNotEmpty && File(page.imagePath).existsSync()) {
        if (_imageQuality < 0.98) {
          final originalBytes = await File(page.imagePath).readAsBytes();
          final decoded = img.decodeImage(originalBytes);
          if (decoded != null) {
            final compressed = img.encodeJpg(
              decoded,
              quality: (_imageQuality * 100).toInt().clamp(40, 100),
            );
            final tempDir = Directory.systemTemp;
            final sanitized = _sanitizeFilename(docWithPages.document.title);
            final target = File(p.join(tempDir.path, '${sanitized}_p${page.pageIndex + 1}.jpg'));
            await target.writeAsBytes(compressed);
            return target.path;
          }
        }
        return page.imagePath;
      }
    }
    return '';
  }
}
