import 'package:basic_bible/src/app_info.dart';
import 'package:basic_bible/src/widgets/app_about.dart';
import 'package:basic_bible/src/widgets/app_back_button.dart';
import 'package:basic_bible/src/widgets/open_external_link.dart';
import 'package:basic_bible/src/widgets/system_inset_padding.dart';
import 'package:flutter/material.dart';

/// Thanks to PopGTN, who created Basic Bible, the app this one is built on.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Credits & Thanks'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16).withSystemBottom(context),
        children: [
          Text(
            'Thank you, PopGTN',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'From Gravel Hill Bible is built on Basic Bible, created by '
            'PopGTN (Joshua Mckenna). He built the app this one grew from, '
            'shared it openly under the Apache License 2.0, and inspired the '
            'direction this app has taken. Without his work, this app would '
            'not exist.',
          ),
          const SizedBox(height: 20),
          Text(
            'What PopGTN built',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const _Credit(Icons.menu_book, 'The Bible reader, in verse-list and document views'),
          const _Credit(Icons.edit_note, 'Notes, highlights and labels'),
          const _Credit(Icons.download, 'The translation catalog and downloads'),
          const _Credit(Icons.vertical_split, 'The split-view reader and Bible search'),
          const _Credit(Icons.cloud_sync, 'Google Drive sync for notes'),
          const _Credit(Icons.link, 'Links that open a verse in the reader'),
          const _Credit(Icons.code, 'The Bible parser for USFX, OSIS, Zefania and USFM texts'),
          const SizedBox(height: 12),
          Text(
            'Find his work',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          _LinkTile(
            icon: Icons.person_outline,
            title: 'PopGTN on GitHub',
            url: 'https://github.com/PopGTN',
          ),
          _LinkTile(
            icon: Icons.favorite_border,
            title: 'Basic Bible, the original app',
            url: originalProjectUrl,
          ),
          _LinkTile(
            icon: Icons.code,
            title: 'The Bible parser (bible_parser_flutter)',
            url: 'https://github.com/PopGTN/bible_parser_flutter',
          ),
          _LinkTile(
            icon: Icons.library_books_outlined,
            title: 'Translation data (bible-data)',
            url: 'https://github.com/PopGTN/bible-data',
          ),
          const Divider(height: 32),
          Text(
            'This version',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Built and maintained by From Gravel Hill Enterprises.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          _LinkTile(
            icon: Icons.public,
            title: 'fromgravelhill.ca',
            url: publisherUrl,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open-source licenses'),
            onTap: () => showAppLicenses(context),
          ),
        ],
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => openExternalLink(url),
    );
  }
}
