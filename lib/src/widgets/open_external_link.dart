import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Opens [url] in the browser (a new tab on web, the external browser/app
/// elsewhere). Failures are ignored: a link that cannot open should not crash.
Future<void> openExternalLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  if (kIsWeb) {
    try {
      await launchUrlString(url, webOnlyWindowName: '_blank');
    } catch (_) {}
    return;
  }

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {}
}
