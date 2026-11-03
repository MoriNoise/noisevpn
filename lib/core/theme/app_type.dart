import 'dart:ui' show FontFeature;

import 'package:flutter/painting.dart';

/// Type scale. Colours are applied at the call site from AppTokens.
abstract final class AppType {
  static const display = TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15);
  static const headline = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3);
  static const title = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.55);
  static const label = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4);
  static const caption = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.4);

  /// Big numbers (speeds, timer) with fixed-width digits so they don't jitter.
  static const metric = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
