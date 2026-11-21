import 'package:flutter_riverpod/legacy.dart';

/// Tab indexes inside the home shell (same order as the bottom bar):
/// Bible (0, the main tab), Settings (1), Extras (2).
const int bibleTabIndex = 0;
const int settingsTabIndex = 1;
const int extrasTabIndex = 2;

/// ViewModel for the selected tab inside the authenticated home shell.
/// Always starts on the Bible tab.
final homeTabIndexProvider = StateProvider<int>((ref) => bibleTabIndex);
