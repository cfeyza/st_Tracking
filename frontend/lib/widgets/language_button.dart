import 'package:flutter/material.dart';

import '../locale_notifier.dart';

/// Compact language toggle for AppBars — shows the active locale code (EN/TR)
/// and switches to the other locale on tap.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return TextButton.icon(
          icon: const Icon(Icons.language),
          label: Text(locale.languageCode.toUpperCase()),
          onPressed: toggleLocale,
        );
      },
    );
  }
}
