import 'package:basic_bible/l10n/app_localizations.dart';
import 'package:basic_bible/src/features/settings/application/view_models/language_view_model.dart';
import 'package:basic_bible/src/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Names shown in the picker, written in each language itself.
const Map<String, String> _nativeLanguageNames = {
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'zh': '中文',
};

/// Lets the user choose the app's display language. The list comes from the
/// generated localizations, so any language added to lib/l10n shows up here.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    final codes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toList()
          ..sort((a, b) {
            // English first, then alphabetical by code.
            if (a == 'en') return -1;
            if (b == 'en') return 1;
            return a.compareTo(b);
          });

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Language'),
      ),
      body: ListView(
        children: [
          for (final code in codes)
            ListTile(
              title: Text(_nativeLanguageNames[code] ?? code),
              trailing: code == current
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              selected: code == current,
              onTap: () =>
                  ref.read(languageProvider.notifier).setLanguage(code),
            ),
        ],
      ),
    );
  }
}
