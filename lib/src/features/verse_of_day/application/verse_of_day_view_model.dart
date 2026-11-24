import 'package:basic_bible/src/features/reader/application/view_models/bible_library_view_models.dart';
import 'package:basic_bible/src/features/verse_of_day/data/verse_of_day_schedule.dart';
import 'package:basic_bible/src/utils/reference_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which verse to load: [month]/[day] is the Halifax calendar date.
typedef VerseOfDayRequest = ({String translationId, int month, int day});

/// Today's verse with its text, ready to show.
class VerseOfDay {
  const VerseOfDay({
    required this.entry,
    required this.translationId,
    required this.bookName,
    required this.text,
  });

  final VerseOfDayEntry entry;

  /// The translation the text came from (the reader's own, or KJV when the
  /// verse is not available in it).
  final String translationId;
  final String bookName;
  final String text;

  String get referenceLabel =>
      '$bookName ${entry.chapter}:${entry.firstVerse}'
      '${entry.isRange ? '-${entry.lastVerse}' : ''}';
}

const String _fallbackTranslationId = 'kjv';

/// Reads the verse text from the Bible already on the device (no network),
/// in the reader's current translation when it has the verse, else KJV.
final verseOfDayProvider = FutureProvider.autoDispose
    .family<VerseOfDay?, VerseOfDayRequest>((ref, request) async {
      final repository = ref.read(bibleRepositoryProvider);
      final entry = verseForDate(request.month, request.day);

      Future<VerseOfDay?> attempt(String translationId) async {
        try {
          final books = await repository.loadLocalBibleShell(translationId);
          final book = books.where((b) => b.id == entry.bookId).firstOrNull;
          if (book == null) return null;
          final chapter = await repository.loadChapterVerses(
            translationId,
            book.id,
            entry.chapter,
          );
          if (chapter == null) return null;
          final verses = chapter.verses
              .where(
                (v) => v.number >= entry.firstVerse && v.number <= entry.lastVerse,
              )
              .toList();
          if (verses.isEmpty) return null;
          return VerseOfDay(
            entry: entry,
            translationId: translationId,
            bookName: preferredBookName(book),
            text: verses.map((v) => v.text.trim()).join(' '),
          );
        } catch (_) {
          return null;
        }
      }

      final preferred = await attempt(request.translationId);
      if (preferred != null || request.translationId == _fallbackTranslationId) {
        return preferred;
      }
      return attempt(_fallbackTranslationId);
    });
