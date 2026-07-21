import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanvibe_pro/src/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ScanVibeApp smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ScanVibeApp(),
      ),
    );
    // Allow async providers (settings load) to settle
    await tester.pump(const Duration(milliseconds: 200));

    // The app should render some widget tree
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
