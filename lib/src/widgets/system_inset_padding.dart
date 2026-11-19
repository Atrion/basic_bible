import 'package:flutter/widgets.dart';

extension SystemInsetPadding on EdgeInsets {
  /// Adds the system navigation-bar inset (3-button or gesture bar) to the
  /// bottom padding.
  ///
  /// A scrollable that sets its own `padding` loses Flutter's automatic bottom
  /// safe-area spacing, so its last item can end up under the Android
  /// navigation buttons. Use this on such paddings:
  /// `padding: const EdgeInsets.all(16).withSystemBottom(context)`.
  EdgeInsets withSystemBottom(BuildContext context) =>
      copyWith(bottom: bottom + MediaQuery.viewPaddingOf(context).bottom);
}
