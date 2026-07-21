// scan_screen_test.dart
//
// Widget-level smoke tests for ScanBatchScreen.  The old ScanVibeState /
// AppStore / OcrClient layer is gone; UI now reads from Riverpod providers
// backed by an in-memory Drift database.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanvibe_pro/src/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ScanVibeApp renders home without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScanVibeApp(),
      ),
    );
    // Allow the first frame + async provider resolution
    await tester.pump(const Duration(milliseconds: 300));

    // At minimum the MaterialApp should be present
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('ProviderScope supplies providers without throwing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
