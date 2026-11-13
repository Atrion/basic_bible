/// Custom exceptions for the Bible parser.
class BibleParserException implements Exception {
  final String message;
  
  BibleParserException(this.message);
  
  @override
  String toString() => 'BibleParserException: $message';
}

/// Thrown when a parser for a specific format could not be loaded.
class ParserUnavailableError extends BibleParserException {
  ParserUnavailableError(super.message);
}

/// Thrown when the format of a Bible file could not be detected.
class FormatDetectionError extends BibleParserException {
  FormatDetectionError(super.message);
}

/// Thrown when there's an error during the parsing process.
class ParseError extends BibleParserException {
  ParseError(super.message);
}
