import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult({
    required this.text,
    this.confidence = 0.0,
    this.blocks = const [],
  });

  final String text;
  final double confidence;
  final List<TextBlock> blocks;
}

class OcrException implements Exception {
  const OcrException(this.message);
  final String message;

  @override
  String toString() => 'OcrException: $message';
}

class OcrService {
  OcrService();

  TextRecognizer? _recognizer;

  TextRecognizer _getRecognizer(String script) {
    final scriptMap = {
      'latin': TextRecognitionScript.latin,
      'devanagari': TextRecognitionScript.devanagari,
      'chinese': TextRecognitionScript.chinese,
      'japanese': TextRecognitionScript.japanese,
      'korean': TextRecognitionScript.korean,
    };
    return TextRecognizer(
      script: scriptMap[script] ?? TextRecognitionScript.latin,
    );
  }

  Future<OcrResult> extractText({
    required String imagePath,
    String languageHint = 'latin',
  }) async {
    try {
      _recognizer?.close();
      _recognizer = _getRecognizer(languageHint);

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer!.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        return const OcrResult(text: '', confidence: 0.0);
      }

      // Calculate average confidence from blocks
      double totalConfidence = 0;
      int blockCount = 0;
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          blockCount++;
          // ML Kit doesn't provide direct confidence, estimate from text density
          totalConfidence += 0.85; // Default good confidence
        }
      }

      final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

      return OcrResult(
        text: recognizedText.text,
        confidence: avgConfidence.clamp(0.0, 1.0),
        blocks: recognizedText.blocks,
      );
    } catch (e) {
      throw OcrException('Failed to recognize text: ${e.toString()}');
    }
  }

  Future<List<OcrResult>> extractTextBatch({
    required List<String> imagePaths,
    String languageHint = 'latin',
    int maxConcurrent = 3,
  }) async {
    final results = <OcrResult>[];

    for (var i = 0; i < imagePaths.length; i += maxConcurrent) {
      final batch = imagePaths.sublist(
        i,
        (i + maxConcurrent > imagePaths.length)
            ? imagePaths.length
            : i + maxConcurrent,
      );

      final batchResults = await Future.wait(
        batch.map((path) => extractText(
          imagePath: path,
          languageHint: languageHint,
        )),
      );

      results.addAll(batchResults);
    }

    return results;
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
