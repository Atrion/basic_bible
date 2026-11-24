import 'package:basic_bible/l10n/app_localizations.dart';
import 'package:basic_bible/src/app_info.dart';
import 'package:basic_bible/src/widgets/open_external_link.dart';
import 'package:flutter/material.dart';

const String _appName = 'From Gravel Hill Bible';
const String _legalese =
    'Free and open source under the Apache License 2.0.\n'
    'Built and maintained by From Gravel Hill Enterprises.\n'
    'Built on Basic Bible, created by PopGTN.\n'
    'The license and rights notice for each Bible translation is shown with '
    'its text.';

Widget _appIcon() => ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.asset('assets/icon/app_icon.png', width: 48, height: 48),
);

/// About dialog with Flutter's built-in "View licenses" button (#88).
void showAppAbout(BuildContext context) {
  final t = AppLocalizations.of(context)!;
  showAboutDialog(
    context: context,
    applicationName: _appName,
    applicationVersion: appVersion.isEmpty ? null : appVersion,
    applicationIcon: _appIcon(),
    applicationLegalese: _legalese,
    children: [
      const SizedBox(height: 16),
      Text(t.aboutDescription),
      const SizedBox(height: 8),
      Wrap(
        spacing: 4,
        children: [
          TextButton.icon(
            onPressed: () => openExternalLink(publisherUrl),
            icon: const Icon(Icons.public, size: 18),
            label: const Text('fromgravelhill.ca'),
          ),
          TextButton.icon(
            onPressed: () => openExternalLink(appRepositoryUrl),
            icon: const Icon(Icons.code, size: 18),
            label: const Text('Source code'),
          ),
          TextButton.icon(
            onPressed: () => openExternalLink(originalProjectUrl),
            icon: const Icon(Icons.favorite_border, size: 18),
            label: const Text('Original project'),
          ),
        ],
      ),
    ],
  );
}

/// The open-source licenses page: every pub package and the Flutter engine
/// (collected by Flutter at build time) plus registerAdditionalLicenses().
void showAppLicenses(BuildContext context) {
  showLicensePage(
    context: context,
    applicationName: _appName,
    applicationVersion: appVersion.isEmpty ? null : appVersion,
    applicationIcon: Padding(
      padding: const EdgeInsets.all(8),
      child: _appIcon(),
    ),
    applicationLegalese: _legalese,
  );
}
