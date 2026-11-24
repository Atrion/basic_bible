// #88: code shipped outside pub must appear on the open-source licenses page.

import 'package:basic_bible/src/services/additional_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every listed license file exists and is not empty', () async {
    for (final license in kAdditionalLicenses) {
      final text = await rootBundle.loadString(license.assetPath);
      expect(text.trim(), isNotEmpty, reason: license.assetPath);
    }
  });

  test('the Basic Bible notice is listed everywhere, sql.js on web only',
      () async {
    LicenseRegistry.reset();
    registerAdditionalLicenses(isWeb: false);
    final native = await LicenseRegistry.licenses.toList();
    expect(native.map((e) => e.packages.single).toList(), [
      'Basic Bible (created by PopGTN)',
    ]);
    final notice = native.single.paragraphs.map((p) => p.text).join('\n');
    expect(notice, contains('PopGTN'));
    expect(notice, contains('Apache License'));

    LicenseRegistry.reset();
    registerAdditionalLicenses(isWeb: true);
    final web = await LicenseRegistry.licenses.toList();
    expect(web.map((e) => e.packages.single).toList(), [
      'Basic Bible (created by PopGTN)',
      'sql.js',
    ]);
    final sql = web.last.paragraphs.map((p) => p.text).join('\n');
    expect(sql, contains('MIT license'));
    expect(sql, contains('Copyright (c) 2017 sql.js authors'));
    LicenseRegistry.reset();
  });
}
