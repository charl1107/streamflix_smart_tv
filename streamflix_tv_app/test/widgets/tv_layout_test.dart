import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/config/tv_layout.dart';

void main() {
  Widget buildLayoutHarness({required Size size, required Widget child}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(builder: (_) => child),
      ),
    );
  }

  testWidgets('uses readable 1080p TV layout dimensions', (tester) async {
    double? heroHeight;
    double? railHeight;
    double? posterHeight;
    int? columns;

    await tester.pumpWidget(
      buildLayoutHarness(
        size: const Size(1920, 1080),
        child: Builder(
          builder: (context) {
            heroHeight = TvLayout.heroHeight(context);
            railHeight = TvLayout.railHeight(context);
            posterHeight = TvLayout.posterHeight(context);
            columns = TvLayout.gridColumns(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(heroHeight, closeTo(561.6, 0.01));
    expect(railHeight, greaterThan(posterHeight!));
    expect(columns, 8);
  });

  testWidgets('caps 4K scaling to preserve the shared web design', (tester) async {
    double? heroHeight;
    double? inset;
    int? columns;

    await tester.pumpWidget(
      buildLayoutHarness(
        size: const Size(3840, 2160),
        child: Builder(
          builder: (context) {
            heroHeight = TvLayout.heroHeight(context);
            inset = TvLayout.horizontalInset(context);
            columns = TvLayout.gridColumns(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(heroHeight, 760);
    expect(inset, 46.4);
    expect(columns, 8);
  });
}
