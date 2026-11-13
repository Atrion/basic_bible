import 'dart:async';
import 'dart:io';

import 'parsers/parsers.dart';
import 'errors.dart';
import 'book.dart';
import 'verse.dart';

/// Main class for parsing Bible files in various formats.
class BibleParser {
  /// The source of the Bible data, can be a File, String, or other data source.
  final dynamic _source;
  
  /// The format of the Bible data.
  late final String format;
  
  /// Creates a new Bible parser with the given source.
  /// 
  /// If [format] is not provided, it will be detected automatically.
  BibleParser(this._source, {String? format}) {
    this.format = format ?? _detectFormat();
  }
  
  /// Creates a new Bible parser from a string containing XML content.
  /// 
  /// If [format] is not provided, it will be detected automatically.
  factory BibleParser.fromString(String xmlContent, {String? format}) {
    return BibleParser(xmlContent, format: format);
  }
  
  /// Gets a stream of all books in the Bible.
  Stream<Book> get books async* {
    final parser = _getParser();
    yield* parser.parseBooks();
  }
  
  /// Gets a stream of all verses in the Bible.
  Stream<Verse> get verses async* {
    final parser = _getParser();
    yield* parser.parseVerses();
  }
  
  /// Gets the appropriate parser for the detected format.
  BaseParser _getParser() {
    try {
      switch (format.toUpperCase()) {
        case 'USFX':
          return UsfxParser(_source);
        case 'OSIS':
          return OsisParser(_source);
        case 'ZEFANIA':
          return ZefaniaParser(_source);
        default:
          throw ParserUnavailableError('Parser for $format could not be loaded.');
      }
    } catch (e, stackTrace) {
      throw BibleParserException('Failed to get parser for format $format: $e, $stackTrace');
    }
  }
  
  /// Detects the format of the Bible data.
  String _detectFormat() {
    // Since we can't use async in a constructor, we'll do a synchronous check
    // This is not ideal but necessary for the constructor pattern
    String content = '';
    
    try {
      if (_source is File) {
        // Handle File source (not available on web)
        try {
          content = _source.readAsStringSync();
        } catch (e) {
          throw FormatDetectionError('Error reading file: $e');
        }
      } else if (_source is String) {
        // For web compatibility, assume String is always content
        // This avoids using File.existsSync() which doesn't work on web
        content = _source;
      } else {
        throw FormatDetectionError('Unsupported source type: ${_source.runtimeType}');
      }
      
      // Check a small sample of the content for format detection
      final sample = content.length > 1000 ? content.substring(0, 1000) : content;
      
      if (sample.contains('<usfx') || sample.contains('<USFX')) return 'USFX';
      if (sample.contains('<osis') || sample.contains('<osisText')) return 'OSIS';
      if (sample.contains('<xmlbible') || sample.contains('<XMLBIBLE')) return 'ZEFANIA';
      
      throw FormatDetectionError('Could not detect Bible format');
    } catch (e) {
      // Default to OSIS format if detection fails
      return 'OSIS';
    }
  }
}
