import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanvibe_pro/src/app.dart';
import 'package:scanvibe_pro/src/services/app_store.dart';
import 'package:scanvibe_pro/src/services/ocr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows language onboarding first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = await ScanVibeState.load(
      store: AppStore(preferences),
      ocrClient: _FakeOcrClient(),
    );

    await tester.pumpWidget(ScanVibeApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('shows document workspace after onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({
      'scanvibe.onboarding_complete': true,
      'scanvibe.locale': 'en',
    });
    final preferences = await SharedPreferences.getInstance();
    final state = await ScanVibeState.load(
      store: AppStore(preferences),
      ocrClient: _FakeOcrClient(),
    );

    await tester.pumpWidget(ScanVibeApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Documents'), findsWidgets);
    expect(find.text('No documents yet'), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
  });
}

class _FakeOcrClient implements OcrClient {
  @override
  Future<OcrResult> extractText({
    required String imagePath,
    required String languageHint,
  }) async {
    return const OcrResult(text: 'Example text', confidence: 0.98);
  }
}
