import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/scanvibe_localizations.dart';
import 'widgets/language_picker.dart';

class OnboardingLanguageScreen extends StatelessWidget {
  const OnboardingLanguageScreen({super.key, required this.state});

  final ScanVibeState state;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.text('languageTitle'),
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.text('languageSubtitle'),
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  LanguagePicker(
                    selectedLocale: state.locale,
                    onChanged: state.setLocale,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: state.completeOnboarding,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(strings.text('continueAction')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
