import 'package:flutter/material.dart';

import '../../l10n/scanvibe_localizations.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selectedLocale,
    required this.onChanged,
  });

  final Locale selectedLocale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = ScanVibeLocalizations.of(context);
    final languages = [
      _LanguageOption(
        locale: const Locale('en'),
        label: strings.text('english'),
      ),
      _LanguageOption(
        locale: const Locale('es'),
        label: strings.text('spanish'),
      ),
      _LanguageOption(
        locale: const Locale('bn'),
        label: strings.text('bengali'),
      ),
      _LanguageOption(
        locale: const Locale('fr'),
        label: strings.text('french'),
      ),
      _LanguageOption(
        locale: const Locale('de'),
        label: strings.text('german'),
      ),
      _LanguageOption(
        locale: const Locale('ar'),
        label: strings.text('arabic'),
      ),
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: languages.map((language) {
        final isSelected =
            selectedLocale.languageCode == language.locale.languageCode;
        return ChoiceChip(
          label: Text(language.label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onChanged(language.locale);
            }
          },
        );
      }).toList(),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.locale, required this.label});

  final Locale locale;
  final String label;
}
