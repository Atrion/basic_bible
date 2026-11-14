import 'package:flutter_riverpod/legacy.dart';

/// Tab indexes inside the authenticated shell: Bible is the main tab (0),
/// Menu is 1. The old Home tab was removed.
const int bibleTabIndex = 0;

/// ViewModel for the selected tab inside the authenticated home shell.
/// Always starts on the Bible tab.
final homeTabIndexProvider = StateProvider<int>((ref) => bibleTabIndex);
