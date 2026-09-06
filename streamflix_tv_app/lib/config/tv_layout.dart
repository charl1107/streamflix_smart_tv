import 'package:flutter/widgets.dart';

/// Shared large-screen sizing for the Flutter web and Android TV surfaces.
/// Values are intentionally bounded so 1080p remains comfortably readable and
/// 4K gains breathing room without making the UI visually diverge from web.
class TvLayout {
  static double _scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 1920).clamp(1.0, 1.45).toDouble();
  }

  static double horizontalInset(BuildContext context) => 32 * _scale(context);

  static double sectionGap(BuildContext context) => 16 * _scale(context);

  static double headerTopInset(BuildContext context) => 12 * _scale(context);

  static double heroHeight(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.52).clamp(440.0, 760.0).toDouble();
  }

  static double posterWidth(BuildContext context) => 172 * _scale(context);

  static double posterHeight(BuildContext context) => posterWidth(context) * 1.5;

  static double railHeight(BuildContext context) => posterHeight(context) + 58;

  static int gridColumns(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - (horizontalInset(context) * 2);
    return (availableWidth / (posterWidth(context) + sectionGap(context)))
        .floor()
        .clamp(4, 8);
  }
}
