/// Build metadata. The release workflow passes the version with
/// `--dart-define=APP_VERSION=0.07`; local builds leave it empty.
const String appVersion = String.fromEnvironment('APP_VERSION');

/// Where the source for this app lives.
const String appRepositoryUrl = 'https://github.com/Atrion/basic_bible';
const String originalProjectUrl = 'https://github.com/PopGTN/basic_bible';
const String publisherUrl = 'https://fromgravelhill.ca/';
