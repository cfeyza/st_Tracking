import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

final localeNotifier = ValueNotifier<Locale>(const Locale('tr'));

Future<void> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_kLocaleKey);
  if (code != null) {
    localeNotifier.value = Locale(code);
  }
}

void toggleLocale() {
  final next = localeNotifier.value.languageCode == 'tr'
      ? const Locale('en')
      : const Locale('tr');
  localeNotifier.value = next;
  SharedPreferences.getInstance()
      .then((prefs) => prefs.setString(_kLocaleKey, next.languageCode));
}
