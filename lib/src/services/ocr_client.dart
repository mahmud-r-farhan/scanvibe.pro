import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  const OcrResult({required this.text, required this.confidence});

  final String text;
  final double confidence;
}

abstract class OcrClient {
  Future<OcrResult> extractText({
    required String imagePath,
    required String languageHint,
  });
}

class LocalOcrClient implements OcrClient {
  LocalOcrClient({TextRecognizer? recognizer}) {
    if (recognizer != null) {
      _recognizers[TextRecognitionScript.latin] = recognizer;
    }
  }

  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};

  @override
  Future<OcrResult> extractText({
    required String imagePath,
    required String languageHint,
  }) async {
    try {
      final script = _getScriptForHint(languageHint);
      final recognizer = _recognizers.putIfAbsent(
        script,
        () => TextRecognizer(script: script),
      );
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      final text = recognizedText.text.trim();
      final confidence = _estimateConfidence(recognizedText, text);
      return OcrResult(text: text, confidence: confidence);
    } catch (error) {
      throw OcrException('Could not recognize text on this device: $error');
    }
  }

  TextRecognitionScript _getScriptForHint(String hint) {
    switch (hint.toLowerCase()) {
      case 'devanagari':
      case 'hi':
        return TextRecognitionScript.devanagiri;
      case 'chinese':
      case 'zh':
        return TextRecognitionScript.chinese;
      case 'japanese':
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'korean':
      case 'ko':
        return TextRecognitionScript.korean;
      case 'latin':
      default:
        return TextRecognitionScript.latin;
    }
  }

  double _estimateConfidence(RecognizedText recognizedText, String text) {
    if (text.isEmpty) {
      return 0;
    }
    final elements = recognizedText.blocks
        .expand((block) => block.lines)
        .expand((line) => line.elements)
        .toList();
    if (elements.isEmpty) {
      return 0.75;
    }
    final knownConfidences = elements
        .map((element) => element.confidence)
        .whereType<double>()
        .toList();
    if (knownConfidences.isEmpty) {
      return 0.8;
    }
    return knownConfidences.reduce((a, b) => a + b) / knownConfidences.length;
  }
}

class OcrException implements Exception {
  const OcrException(this.message);

  final String message;

  @override
  String toString() => message;
}
