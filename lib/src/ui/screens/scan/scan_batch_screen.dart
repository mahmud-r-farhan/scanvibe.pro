import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../database/app_database.dart';
import '../../../providers/documents_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ocr_service.dart';
import '../../../theme/app_colors.dart';

class ScanBatchScreen extends ConsumerStatefulWidget {
  const ScanBatchScreen({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  ConsumerState<ScanBatchScreen> createState() => _ScanBatchScreenState();
}

class _ScanBatchScreenState extends ConsumerState<ScanBatchScreen> {
  bool _isProcessingOcr = false;
  bool _isExporting = false;
  Set<String> _selectedPageIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documentsState = ref.watch(documentsProvider);
    final documentWithPages = documentsState.documents
        .where((d) => d.document.id == widget.documentId)
        .toList();

    if (documentWithPages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Batch Scan'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Document not found',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final doc = documentWithPages.first;
    final pages = doc.pages;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : const BackButton(),
        title: _isSelectionMode
            ? Text('${_selectedPageIds.length} selected')
            : Text(
                'Pages (${pages.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () => _selectAllPages(pages),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Selected',
              onPressed: _selectedPageIds.isNotEmpty
                  ? () => _confirmDeleteSelected(context)
                  : null,
            ),
          ] else ...[
            if (pages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Export PDF',
                onPressed: _isExporting ? null : _exportPdf,
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(theme, pages, doc),
          Expanded(
            child: pages.isEmpty
                ? _buildEmptyState(theme)
                : _buildPageGrid(theme, pages),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme, pages, doc),
    );
  }

  Widget _buildStatsBar(
    ThemeData theme,
    List pages,
    DocumentWithPages doc,
  ) {
    final completedCount =
        pages.where((p) => p.ocrStatus == 'complete').length;
    final queuedCount = pages.where((p) => p.ocrStatus == 'queued').length;
    final failedCount = pages.where((p) => p.ocrStatus == 'failed').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStatChip(
            theme: theme,
            icon: Icons.description_outlined,
            label: '${pages.length} pages',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          if (completedCount > 0)
            _buildStatChip(
              theme: theme,
              icon: Icons.check_circle_outline,
              label: '$completedCount OCR',
              color: AppColors.ocrComplete,
            ),
          if (completedCount > 0) const SizedBox(width: 8),
          if (queuedCount > 0)
            _buildStatChip(
              theme: theme,
              icon: Icons.hourglass_empty,
              label: '$queuedCount queued',
              color: AppColors.ocrQueued,
            ),
          if (queuedCount > 0) const SizedBox(width: 8),
          if (failedCount > 0)
            _buildStatChip(
              theme: theme,
              icon: Icons.error_outline,
              label: '$failedCount failed',
              color: AppColors.ocrFailed,
            ),
          const Spacer(),
          Text(
              _formatDate(doc.document.updatedAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No pages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to capture\nyour first page',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageGrid(ThemeData theme, List<ScanPageData> pages) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pages.length,
      onReorderItem: (oldIndex, newIndex) => _reorderPages(pages, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final page = pages[index];
        final isSelected = _selectedPageIds.contains(page.id);
        final imagePath = page.imagePath;
        final fileExists = imagePath.isNotEmpty && File(imagePath).existsSync();

        return GestureDetector(
          key: ValueKey(page.id),
          onTap: () {
            if (_isSelectionMode) {
              _togglePageSelection(page.id);
            } else {
              _viewPage(page);
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            if (!_isSelectionMode) {
              _enterSelectionMode(page.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryLight
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Page number badge
                Container(
                  width: 44,
                  height: 88,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSelectionMode)
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryLight
                              : theme.colorScheme.onSurfaceVariant,
                          size: 22,
                        )
                      else
                        Text(
                          '${index + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primaryLight
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),

                // Thumbnail
                Container(
                  width: 66,
                  height: 88,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: fileExists
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 24,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 24,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                // Page info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildOcrStatusBadge(theme, page.ocrStatus),
                      if (page.extractedText != null &&
                          page.extractedText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          page.extractedText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('View'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ocr',
                        child: Row(
                          children: [
                            const Icon(Icons.document_scanner_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(page.ocrStatus == 'complete'
                                ? 'Re-run OCR'
                                : 'Run OCR'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18,
                                color: AppColors.error),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewPage(page);
                        case 'ocr':
                          _runSinglePageOcr(page);
                        case 'delete':
                          _confirmDeletePage(context, page);
                      }
                    },
                  ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOcrStatusBadge(ThemeData theme, dynamic ocrStatus) {
    Color color;
    String label;
    IconData icon;

    final statusStr = ocrStatus is String ? ocrStatus : ocrStatus.toString();

    switch (statusStr) {
      case 'complete':
        color = AppColors.ocrComplete;
        label = 'OCR Complete';
        icon = Icons.check_circle_outline;
      case 'processing':
        color = AppColors.ocrProcessing;
        label = 'Processing...';
        icon = Icons.hourglass_top;
      case 'failed':
        color = AppColors.ocrFailed;
        label = 'OCR Failed';
        icon = Icons.error_outline;
      default:
        color = AppColors.ocrQueued;
        label = 'Queued';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, List pages, DocumentWithPages doc) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Add page button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addMorePages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Process OCR button
          Expanded(
            child: FilledButton.icon(
              onPressed: (_isProcessingOcr || pages.isEmpty) ? null : _processOcr,
              icon: _isProcessingOcr
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.text_snippet_outlined, size: 18),
              label: Text(_isProcessingOcr ? 'OCR...' : 'OCR'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                disabledForegroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Export PDF button
          Expanded(
            child: FilledButton.icon(
              onPressed: (_isExporting || pages.isEmpty) ? null : _exportPdf,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 18),
              label: Text(_isExporting ? 'PDF...' : 'PDF'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                disabledForegroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _enterSelectionMode(String initialPageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedPageIds = {initialPageId};
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPageIds = {};
    });
  }

  void _togglePageSelection(String pageId) {
    setState(() {
      final selected = Set<String>.from(_selectedPageIds);
      if (selected.contains(pageId)) {
        selected.remove(pageId);
      } else {
        selected.add(pageId);
      }
      _selectedPageIds = selected;

      if (_selectedPageIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllPages(List<ScanPageData> pages) {
    setState(() {
      _selectedPageIds = pages.map((p) => p.id).toSet();
    });
  }

  void _reorderPages(List<ScanPageData> pages, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final pageIds = pages.map((p) => p.id).toList();
    final item = pageIds.removeAt(oldIndex);
    pageIds.insert(newIndex, item);

    ref.read(documentsProvider.notifier).reorderPages(widget.documentId, List<String>.from(pageIds));
  }

  void _viewPage(dynamic page) {
    final ocrText = page.extractedText ?? '';
    if (ocrText.isNotEmpty) {
      context.push(
        '/text/view',
        extra: {
          'text': ocrText,
          'title': 'Page ${page.pageIndex + 1}',
        },
      );
    }
  }

  void _confirmDeletePage(BuildContext context, dynamic page) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Delete Page'),
        content: Text(
          'Are you sure you want to delete Page ${page.pageIndex + 1}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deletePage(page.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(BuildContext context) {
    final count = _selectedPageIds.length;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: Text('Delete $count ${count == 1 ? 'page' : 'pages'}'),
        content: Text(
          'Are you sure you want to delete $count ${count == 1 ? 'page' : 'pages'}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              for (final pageId in _selectedPageIds) {
                _deletePage(pageId);
              }
              _exitSelectionMode();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePage(String pageId) async {
    await ref.read(documentsProvider.notifier).deletePage(pageId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Page deleted'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addMorePages() {
    context.push('/scan');
  }

  Future<void> _processOcr() async {
    setState(() => _isProcessingOcr = true);

    try {
      final documentsState = ref.read(documentsProvider);
      final doc = documentsState.documents
          .where((d) => d.document.id == widget.documentId)
          .toList();

      if (doc.isEmpty) return;

      final queuedPages = doc.first.pages
          .where((p) => p.ocrStatus == 'queued' || p.ocrStatus == 'failed')
          .toList();

      if (queuedPages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All pages already processed'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final ocrService = ref.read(ocrServiceProvider);
      final ocrLanguage = ref.read(settingsProvider).ocrLanguage;

      for (final page in queuedPages) {
        await ref.read(documentsProvider.notifier).updatePageOcrStatus(
              pageId: page.id,
              status: 'processing',
            );

        try {
          if (!File(page.imagePath).existsSync()) {
            throw Exception('Page image file does not exist');
          }
          final result = await ocrService.extractText(
            imagePath: page.imagePath,
            languageHint: ocrLanguage,
          );
          await ref.read(documentsProvider.notifier).updatePageOcrStatus(
                pageId: page.id,
                status: 'complete',
                extractedText: result.text.isNotEmpty ? result.text : null,
                confidence: result.confidence,
              );
        } catch (e) {
          await ref.read(documentsProvider.notifier).updatePageOcrStatus(
                pageId: page.id,
                status: 'failed',
                errorMessage: e.toString(),
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR completed for ${queuedPages.length} pages'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingOcr = false);
      }
    }
  }

  Future<void> _runSinglePageOcr(ScanPageData page) async {
    final ocrService = ref.read(ocrServiceProvider);
    final ocrLanguage = ref.read(settingsProvider).ocrLanguage;

    await ref.read(documentsProvider.notifier).updatePageOcrStatus(
          pageId: page.id,
          status: 'processing',
        );

    try {
      if (!File(page.imagePath).existsSync()) {
        throw Exception('Page image file does not exist');
      }
      final result = await ocrService.extractText(
        imagePath: page.imagePath,
        languageHint: ocrLanguage,
      );
      await ref.read(documentsProvider.notifier).updatePageOcrStatus(
            pageId: page.id,
            status: 'complete',
            extractedText: result.text.isNotEmpty ? result.text : null,
            confidence: result.confidence,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page ${page.pageIndex + 1} OCR complete'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      await ref.read(documentsProvider.notifier).updatePageOcrStatus(
            pageId: page.id,
            status: 'failed',
            errorMessage: e.toString(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);

    try {
      final documentsState = ref.read(documentsProvider);
      final doc = documentsState.documents
          .where((d) => d.document.id == widget.documentId)
          .toList();

      if (doc.isEmpty || !mounted) return;

      final pdf = await _generatePdf(doc.first);

      if (!mounted) return;

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${doc.first.document.title.replaceAll(' ', '_')}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF exported successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
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
        setState(() => _isExporting = false);
      }
    }
  }

  final Map<String, pw.MemoryImage> _pdfImages = {};

  Future<pw.Document> _generatePdf(DocumentWithPages doc) async {
    final pdf = pw.Document();

    // Pre-load all page images before building the PDF widget tree
    _pdfImages.clear();
    for (final page in doc.pages) {
      final path = page.imagePath;
      if (path.isNotEmpty && File(path).existsSync()) {
        try {
          final bytes = await File(path).readAsBytes();
          _pdfImages[path] = pw.MemoryImage(bytes);
        } catch (_) {}
      }
    }

    for (var i = 0; i < doc.pages.length; i++) {
      final page = doc.pages[i];
      final imagePath = page.imagePath;

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  '${doc.document.title} - Page ${i + 1}',
                  style: const pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                if (File(imagePath).existsSync() && _pdfImages.containsKey(imagePath))
                  pw.Expanded(
                    child: pw.Image(_pdfImages[imagePath]!, fit: pw.BoxFit.contain),
                  ),
                if (page.extractedText != null &&
                    page.extractedText!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(page.extractedText!),
                ],
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}
