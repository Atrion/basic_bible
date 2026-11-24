import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Extras" tab: Notes, Prayer List and other extras. About, Help and the
/// source link live in Settings.
class MenuTab extends ConsumerWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // Notes
        ListTile(
          leading: const Icon(Icons.note),
          title: const Text("Notes"),
          onTap: () => context.go('/home/notes'),
        ),

        // Prayer List
        ListTile(
          leading: const Icon(Icons.list_alt),
          title: const Text("Prayer List"),
          onTap: () => context.push('/home/prayer-list'),
        ),

        // Verse of the Day
        ListTile(
          leading: const Icon(Icons.auto_stories),
          title: const Text("Verse of the Day"),
          onTap: () => context.push('/home/verse-of-the-day'),
        ),
      ],
    );
  }
}
