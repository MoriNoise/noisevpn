import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Which family of layouts the app draws. Ported from the Palgam panel.
///
/// ## Why this exists
///
/// [AppScaler] draws desktop builds on a fixed design canvas and rewrites
/// `MediaQuery.size` to that canvas. Anything below it that asks "how big is
/// the screen?" therefore always hears "desktop".
///
/// The form factor is decided once, in `MaterialApp.builder`, from the *real*
/// window size and platform, before any scaling happens. Everything below
/// reads it from [FormFactorScope] instead of from `MediaQuery`.
///
/// ## The rule
///
///  * Windows, macOS, Linux and web → [desktop], always. Desktop always gets
///    the sidebar layout and the scaler.
///  * Android and iOS → [phone] when the shortest side is under 600 dp,
///    [tablet] otherwise. Shortest side (not width) so rotating a device never
///    flips the layout family.
///
/// ## Testing the phone UI without a phone
///
/// ```
/// flutter run -d macos --dart-define=FORM_FACTOR=phone
/// ```
///
/// Accepts `phone`, `tablet` or `desktop`. Resize the window to a phone shape
/// and the mobile shell runs on your desktop.
enum FormFactor {
  phone,
  tablet,
  desktop;

  bool get isDesktop => this == FormFactor.desktop;

  /// Phone or tablet: a touch layout without the desktop scaler.
  bool get isTouch => !isDesktop;

  static const double tabletShortestSide = 600;

  static const String _forced = String.fromEnvironment('FORM_FACTOR');

  static FormFactor resolve(Size size, {TargetPlatform? platform}) {
    switch (_forced) {
      case 'phone':
        return FormFactor.phone;
      case 'tablet':
        return FormFactor.tablet;
      case 'desktop':
        return FormFactor.desktop;
    }

    if (kIsWeb) return FormFactor.desktop;

    final p = platform ?? defaultTargetPlatform;
    final isMobileOs = p == TargetPlatform.android || p == TargetPlatform.iOS;
    if (!isMobileOs) return FormFactor.desktop;

    return size.shortestSide >= tabletShortestSide
        ? FormFactor.tablet
        : FormFactor.phone;
  }
}

/// Carries the [FormFactor] decided in the app builder down the tree.
///
/// Placed above the Navigator, so routes, dialogs and bottom sheets all see
/// it. A widget that has no scope above it is treated as desktop, which keeps
/// tests and previews of desktop widgets working unchanged.
class FormFactorScope extends InheritedWidget {
  final FormFactor factor;

  const FormFactorScope({
    super.key,
    required this.factor,
    required super.child,
  });

  static FormFactor of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FormFactorScope>();
    return scope?.factor ?? FormFactor.desktop;
  }

  @override
  bool updateShouldNotify(FormFactorScope oldWidget) => oldWidget.factor != factor;
}

extension FormFactorContext on BuildContext {
  FormFactor get formFactor => FormFactorScope.of(this);
}
