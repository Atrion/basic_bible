import 'package:basic_bible/src/features/annotations/application/view_models/annotation_preferences_view_models.dart';
import 'package:basic_bible/src/features/reader/application/view_models/reader_preferences_view_models.dart';
import 'package:basic_bible/src/features/settings/application/view_models/language_view_model.dart';
import 'package:basic_bible/src/features/settings/application/view_models/reader_display_preferences_view_models.dart';
import 'package:basic_bible/src/features/settings/application/view_models/theme_view_model.dart';
import 'package:basic_bible/src/services/font_size_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// After a sync wrote new settings into SharedPreferences, make the running
/// app pick them up. Each provider reads its preference only when it is
/// created, so invalidating it re-reads the value.
///
/// Keep this in step with kSyncedSettingKeys (extras_merge.dart): every synced
/// setting needs its provider here.
void reloadSyncedSettings(Ref ref, SharedPreferences prefs) {
  FontSizeService.instance.load(prefs);
  ref.invalidate(themeProvider);
  ref.invalidate(languageProvider);
  ref.invalidate(boldDivineNameProvider);
  ref.invalidate(underlineProperNamesProvider);
  ref.invalidate(underlineWordMetadataProvider);
  ref.invalidate(bracketTranslatorAdditionsProvider);
  ref.invalidate(useSourceBoldStylingProvider);
  ref.invalidate(showSourceDetailsProvider);
  ref.invalidate(continuousScrollingProvider);
  ref.invalidate(showBookIntroductionsProvider);
  ref.invalidate(showVerseSelectorProvider);
  ref.invalidate(readerLayoutModeProvider);
  ref.invalidate(confirmRemoveLinkedVerseProvider);
  ref.invalidate(showNotesAcrossTranslationsProvider);
}
