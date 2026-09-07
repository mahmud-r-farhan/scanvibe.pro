import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/documents_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ocr_service.dart';
import '../../../theme/app_colors.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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

    final doc = docWithPages.document;
    final pages = docWithPages.pages;

    if (_isEditingTitle) {
      _titleController.text = doc.title;
    }

    final completedPages = pages.where((p) => p.ocrStatus == 'complete').length;
    final avgConfidence = pages
        .where((p) => p.confidence != null)
        .fold<double>(0, (sum, p) => sum + (p.confidence ?? 0)) /
        (pages.where((p) => p.confidence != null).length.clamp(1, 999));
    final totalTextLength = docWithPages.combinedText.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: _isEditingTitle
            ? TextField(
                controller: _titleController
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: doc.title.length),
                  ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    ref.read(documentsProvider.notifier).updateDocumentTitle(
                          widget.documentId,
                          value.trim(),
                        );
                  }
                  setState(() => _isEditingTitle = false);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Document title',
                ),
              )
            : Text(doc.title),
        actions: [
          IconButton(
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: doc.isFavorite ? AppColors.warning : null,
            ),
            onPressed: () {
              ref.read(documentsProvider.notifier).toggleFavorite(widget.documentId);
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_page',
                child: Row(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Add Page'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'rename') {
                setState(() => _isEditingTitle = true);
              } else if (value == 'add_page') {
                _addPageFromGallery();
              } else if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.description_outlined,
                  label: '$completedPages/${pages.length} pages',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.text_fields,
                  label: '$totalTextLength chars',
                ),
                const SizedBox(width: 8),
                if (completedPages > 0)
                  _StatChip(
                    icon: Icons.check_circle_outline,
                    label: '${(avgConfidence * 100).toStringAsFixed(0)}% OCR',
                  ),
              ],
            ),
          ),

          // Page Viewer
          if (pages.isNotEmpty)
            Expanded(
              flex: 3,
              child: PageView.builder(
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentPageIndex = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image would be loaded from file here
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Page ${index + 1}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status badge
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _StatusBadge(status: page.ocrStatus),
                          ),
                          // Page number
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}/${pages.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Page indicators
          if (pages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPageIndex == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPageIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

          // Extracted Text Section
          if (docWithPages.combinedText.isNotEmpty)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.text_snippet_outlined,
                            size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Extracted Text',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: docWithPages.combinedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Text copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy all text',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          onPressed: () {},
                          tooltip: 'Share text',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          docWithPages.combinedText,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pages.any((p) => p.ocrStatus == 'failed')
                        ? () => _retryOcr()
                        : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry OCR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/export/${widget.documentId}'),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Export PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPageSheet,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddPageSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/scan');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Import from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(documentsProvider.notifier).deleteDocument(widget.documentId);
              Navigator.pop(context);
              context.go('/documents');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryOcr() async {
    final docsState = ref.read(documentsProvider);
    final docWithPages = docsState.getDocumentById(widget.documentId);
    if (docWithPages == null) return;

    final queuedPages = docWithPages.pages
        .where((p) => p.ocrStatus == 'queued' || p.ocrStatus == 'failed')
        .toList();

    if (queuedPages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All pages are already processed')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processing OCR for ${queuedPages.length} pages...')),
      );
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
          throw Exception('Image file missing');
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
  }

  Future<void> _addPageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (image == null) return;

    final pageId = await ref.read(documentsProvider.notifier).addPageToDocument(
          documentId: widget.documentId,
          imagePath: image.path,
          filterType: 'auto_enhance',
        );

    if (ref.read(settingsProvider).autoProcessOcr) {
      final ocrService = ref.read(ocrServiceProvider);
      final ocrLanguage = ref.read(settingsProvider).ocrLanguage;
      ref.read(documentsProvider.notifier).updatePageOcrStatus(
            pageId: pageId,
            status: 'processing',
          );
      ocrService.extractText(imagePath: image.path, languageHint: ocrLanguage).then((res) {
        ref.read(documentsProvider.notifier).updatePageOcrStatus(
              pageId: pageId,
              status: 'complete',
              extractedText: res.text.isNotEmpty ? res.text : null,
              confidence: res.confidence,
            );
      }).catchError((err) {
        ref.read(documentsProvider.notifier).updatePageOcrStatus(
              pageId: pageId,
              status: 'failed',
              errorMessage: err.toString(),
            );
      });
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'complete' => (AppColors.success, Icons.check_circle),
      'processing' => (AppColors.warning, Icons.hourglass_empty),
      'failed' => (AppColors.error, Icons.error),
      _ => (AppColors.ocrQueued, Icons.schedule),
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
