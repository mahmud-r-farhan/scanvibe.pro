import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/scan_document.dart';

class DocumentExporter {
  Future<String> exportPdf(ScanDocument document) async {
    final pdf = pw.Document();
    for (var index = 0; index < document.pages.length; index++) {
      final page = document.pages[index];
      final file = File(page.imagePath);
      final imageBytes = await file.exists() ? await file.readAsBytes() : null;
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  '${document.title} - Page ${index + 1}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                if (imageBytes != null)
                  pw.Expanded(
                    child: pw.Image(
                      pw.MemoryImage(imageBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                if (page.extractedText.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(page.extractedText),
                ],
              ],
            );
          },
        ),
      );
    }
    final directory = await getApplicationDocumentsDirectory();
    final safeTitle = document.title.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]+'),
      '_',
    );
    final path = '${directory.path}/$safeTitle.pdf';
    await File(path).writeAsBytes(await pdf.save());
    return path;
  }
}
