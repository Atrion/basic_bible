import 'dart:async';
import 'dart:io';

import '../book.dart';
import '../verse.dart';
import '../errors.dart';

/// Base class for all Bible format parsers.
abstract class BaseParser {
  /// The source of the Bible data, can be a File, String, or other data source.
  final dynamic source;
  
  /// Creates a new parser with the given source.
  BaseParser(this.source);
  
  /// Parses the Bible data and returns a stream of books.
  Stream<Book> parseBooks();
  
  /// Parses the Bible data and returns a stream of verses.
  Stream<Verse> parseVerses();
  
  /// Gets the content as a string.
  Future<String> getContent() async {
    try {
      if (source is File) {
        try {
          return await (source as File).readAsString();
        } catch (e) {
          throw ParseError('Error reading file: $e');
        }
      } else if (source is String) {
        // For web compatibility, assume String is always content
        // This avoids using File.exists() which doesn't work on web
        return source;
      } else {
        throw ParseError('Unsupported source type: ${source.runtimeType}');
      }
    } catch (e) {
      // Catch any other unexpected errors
      throw BibleParserException('Failed to get content: $e');
    }
  }
  
  /// Checks if the content matches this parser's format.
  Future<bool> matchesFormat() async {
    final content = await getContent();
    return checkFormat(content);
  }
  
  /// Checks if the given content matches this parser's format.
  bool checkFormat(String content);
}
