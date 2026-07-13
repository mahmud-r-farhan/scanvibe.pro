import 'scan_document.dart';

class DocumentHealth {
  const DocumentHealth({
    required this.completePages,
    required this.queuedPages,
    required this.failedPages,
    required this.totalPages,
  });

  final int completePages;
  final int queuedPages;
  final int failedPages;
  final int totalPages;

  double get completionRatio =>
      totalPages == 0 ? 0 : completePages / totalPages;
  bool get needsAttention => failedPages > 0 || queuedPages > 0;
}

DocumentHealth calculateDocumentHealth(ScanDocument document) {
  var complete = 0;
  var queued = 0;
  var failed = 0;
  for (final page in document.pages) {
    switch (page.ocrStatus) {
      case OcrStatus.complete:
        complete++;
      case OcrStatus.queued:
      case OcrStatus.processing:
        queued++;
      case OcrStatus.failed:
        failed++;
    }
  }
  return DocumentHealth(
    completePages: complete,
    queuedPages: queued,
    failedPages: failed,
    totalPages: document.pages.length,
  );
}
