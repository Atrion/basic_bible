import 'package:flutter_riverpod/legacy.dart';

/// Tab indexes inside the home shell (same order as the bottom bar):
/// Bible (0, the main tab), Menu (1), Settings (2).
const int bibleTabIndex = 0;
const int menuTabIndex = 1;
const int settingsTabIndex = 2;

/// ViewModel for the selected tab inside the authenticated home shell.
/// Always starts on the Bible tab.
final homeTabIndexProvider = StateProvider<int>((ref) => bibleTabIndex);
