import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/services/app_store.dart';
import 'src/services/ocr_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final store = AppStore(preferences);
  final state = await ScanVibeState.load(
    store: store,
    ocrClient: LocalOcrClient(),
  );

  runApp(ScanVibeApp(state: state));
}
