import 'dart:async';

import 'package:basic_bible/src/features/home/application/view_models/reader_link_opener.dart';
import 'package:basic_bible/src/features/reader/application/view_models/reader_session_view_models.dart';
import 'package:basic_bible/src/features/reader/models/reader_deep_link.dart';
import 'package:basic_bible/src/features/verse_of_day/application/verse_of_day_view_model.dart';
import 'package:basic_bible/src/features/verse_of_day/data/halifax_time.dart';
import 'package:basic_bible/src/models/bible_models.dart';
import 'package:basic_bible/src/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// One verse a day, new at midnight in Halifax, Nova Scotia.
class VerseOfDayScreen extends ConsumerStatefulWidget {
  const VerseOfDayScreen({super.key});

  @override
  ConsumerState<VerseOfDayScreen> createState() => _VerseOfDayScreenState();
}

class _VerseOfDayScreenState extends ConsumerState<VerseOfDayScreen> {
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMidnightRefresh();
  }

  /// If the app stays open past midnight, switch to the new verse then.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final wait = timeUntilHalifaxMidnight(DateTime.now()) +
        const Duration(seconds: 1);
    _midnightTimer = Timer(wait, () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy(VerseOfDay verse) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            '${verse.referenceLabel}\n${verse.text}\n'
            '(${verse.translationId.toUpperCase()})',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Verse copied')));
  }

  Future<void> _readInContext(VerseOfDay verse) async {
    await ref
        .read(readerLinkOpenerProvider)
        .open(
          ReaderDeepLink(
            reference: BibleReference(
              bookId: verse.entry.bookId,
              chapter: verse.entry.chapter,
              verse: verse.entry.firstVerse,
            ),
            translationId: verse.translationId,
          ),
        );
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final date = halifaxDate(now);
    final translationId = ref.watch(currentTranslationProvider);
    final verseAsync = ref.watch(
      verseOfDayProvider((
        translationId: translationId,
        month: date.month,
        day: date.day,
      )),
    );
    final dateLabel = DateFormat(
      'EEEE, MMMM d',
    ).format(DateTime.utc(date.year, date.month, date.day));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Verse of the Day'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            dateLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          verseAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => const _VerseMessage(
              'Today\'s verse could not be loaded. Please try again.',
            ),
            data: (verse) {
              if (verse == null) {
                return const _VerseMessage(
                  'Today\'s verse is not available right now.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verse.text,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              height: 1.5,
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${verse.referenceLabel}  ·  '
                            '${verse.translationId.toUpperCase()}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _readInContext(verse),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Read in context'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _copy(verse),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy verse'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'A new verse every day, changing at midnight in Halifax, Nova '
            'Scotia.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseMessage extends StatelessWidget {
  const _VerseMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
