import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../providers/documents_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../enums.dart';

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

    final docWithPages = docsState.documents.firstWhere(
      (d) => d.document.id == widget.documentId,
      orElse: () => throw Exception('Document not found'),
    );

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

          // Export Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
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
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    return switch (format) {
      ExportFormat.pdf => Icons.picture_as_pdf_rounded,
      ExportFormat.jpeg => Icons.image_rounded,
      ExportFormat.txt => Icons.text_snippet_rounded,
    };
  }

  Future<void> _exportDocument() async {
    setState(() => _isExporting = true);

    try {
      final docsState = ref.read(documentsProvider);
      final docWithPages = docsState.documents.firstWhere(
        (d) => d.document.id == widget.documentId,
      );

      if (_selectedFormat == ExportFormat.pdf) {
        await _exportAsPdf(docWithPages);
      } else if (_selectedFormat == ExportFormat.txt) {
        await _exportAsTxt(docWithPages);
      } else {
        await _exportAsJpeg(docWithPages);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document exported as ${_selectedFormat.displayName}')),
        );

        if (_shareAfterExport) {
          // Share logic would go here
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAsPdf(DocumentWithPages docWithPages) async {
    final pdf = pw.Document();

    for (final page in docWithPages.pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Column(
            children: [
              if (page.imagePath.isNotEmpty)
                pw.Expanded(
                  child: pw.Image(
                    pw.MemoryImage(
                      await File(page.imagePath).readAsBytes(),
                    ),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (page.extractedText?.isNotEmpty == true)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Text(
                    page.extractedText!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    await Printing.sharePdf(bytes: await pdf.save(), filename: '${docWithPages.document.title}.pdf');
  }

  Future<void> _exportAsTxt(DocumentWithPages docWithPages) async {
    final text = docWithPages.combinedText;
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/${docWithPages.document.title}.txt');
    await file.writeAsString(text);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }

  Future<void> _exportAsJpeg(DocumentWithPages docWithPages) async {
    final files = <XFile>[];
    for (final page in docWithPages.pages) {
      if (page.imagePath.isNotEmpty) {
        files.add(XFile(page.imagePath));
      }
    }

    if (files.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(files: files),
      );
    }
  }
}
