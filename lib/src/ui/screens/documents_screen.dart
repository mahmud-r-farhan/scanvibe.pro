import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../app.dart';
import '../../l10n/scanvibe_localizations.dart';
import '../../models/document_health.dart';
import '../../models/scan_document.dart';
import '../../services/image_capture_service.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, required this.state});

  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.text('documents')),
            actions: [
              IconButton(
                tooltip: strings.text('processQueue'),
                onPressed: state.isBusy ? null : state.processQueuedPages,
                icon: state.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
              ),
            ],
          ),
          body: state.documents.isEmpty
              ? _EmptyDocuments(state: state)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      state.documents.length +
                      (state.lastError == null ? 1 : 2),
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (state.lastError != null && index == 0) {
                      return _IssueBanner(message: state.lastError!);
                    }
                    final adjustedIndex =
                        index - (state.lastError == null ? 0 : 1);
                    if (adjustedIndex == 0) {
                      return _QueueBanner();
                    }
                    return _DocumentCard(
                      document: state.documents[adjustedIndex - 1],
                      state: state,
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments({required this.state});

  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                strings.text('emptyTitle'),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                strings.text('emptyBody'),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: state.createDocumentFromCamera,
                    icon: const Icon(Icons.photo_camera),
                    label: Text(strings.text('camera')),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.importDocumentFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(strings.text('gallery')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueueBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud_sync_outlined),
        title: Text(strings.text('networkTitle')),
        subtitle: Text(strings.text('ocrQueueNote')),
      ),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  const _IssueBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(strings.text('lastError')),
        subtitle: Text(message),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.state});

  final ScanDocument document;
  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    final health = calculateDocumentHealth(document);
    final firstPage = document.pages.firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PagePreview(page: firstPage),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(strings.pageCount(document.pages.length)),
                      const SizedBox(height: 4),
                      Text(strings.formatDate(document.updatedAt)),
                    ],
                  ),
                ),
                _StatusChip(document: document),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: health.completionRatio),
            if (document.combinedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                document.combinedText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      state.addPage(document.id, ImageSourceKind.camera),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(strings.text('addPage')),
                ),
                FilledButton.icon(
                  onPressed: document.hasFailedPages
                      ? () => state.retryDocument(document.id)
                      : () async {
                          await state.exportDocument(document.id);
                          final path = state.lastExportPath;
                          if (path != null) {
                            final file = File(path);
                            if (await file.exists()) {
                              final bytes = await file.readAsBytes();
                              await Printing.sharePdf(
                                bytes: bytes,
                                filename:
                                    '${document.title.replaceAll(' ', '_')}.pdf',
                              );
                            }
                          }
                        },
                  icon: Icon(
                    document.hasFailedPages
                        ? Icons.refresh
                        : Icons.picture_as_pdf,
                  ),
                  label: Text(
                    document.hasFailedPages
                        ? strings.text('retry')
                        : strings.text('exportPdf'),
                  ),
                ),
                if (document.combinedText.isNotEmpty)
                  IconButton(
                    tooltip: strings.text('copyText'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: document.combinedText),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.text('textCopied')),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined),
                  ),
                IconButton(
                  tooltip: strings.text('delete'),
                  onPressed: () => state.deleteDocument(document.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (state.lastExportPath != null) ...[
              const SizedBox(height: 8),
              Text('${strings.text('exported')}: ${state.lastExportPath}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.page});

  final ScanPage? page;

  @override
  Widget build(BuildContext context) {
    final path = page?.imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 72,
        height: 96,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: path == null || !File(path).existsSync()
            ? const Icon(Icons.description_outlined)
            : Image.file(File(path), fit: BoxFit.cover),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.document});

  final ScanDocument document;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    final status =
        document.pages.any((page) => page.ocrStatus == OcrStatus.processing)
        ? OcrStatus.processing
        : document.pages.any((page) => page.ocrStatus == OcrStatus.failed)
        ? OcrStatus.failed
        : document.pages.any((page) => page.ocrStatus == OcrStatus.queued)
        ? OcrStatus.queued
        : OcrStatus.complete;
    final label = switch (status) {
      OcrStatus.queued => strings.text('queued'),
      OcrStatus.processing => strings.text('processing'),
      OcrStatus.complete => strings.text('complete'),
      OcrStatus.failed => strings.text('failed'),
    };
    return Chip(label: Text(label));
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
