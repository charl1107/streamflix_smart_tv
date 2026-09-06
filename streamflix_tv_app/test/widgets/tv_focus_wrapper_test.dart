import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/widgets/tv_focus_wrapper.dart';

void main() {
  testWidgets('activates the focused control with the remote select key', (tester) async {
    var activationCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvFocusWrapper(
            autofocus: true,
            onTap: () => activationCount++,
            child: const SizedBox(width: 160, height: 64),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);

    expect(activationCount, 1);
  });

  testWidgets('shows a focus outline while the control is focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvFocusWrapper(
            autofocus: true,
            onTap: () {},
            child: const SizedBox(width: 160, height: 64),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final decoration = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(TvFocusWrapper),
        matching: find.byType(AnimatedContainer),
      ),
    ).decoration! as BoxDecoration;

    expect(decoration.border, isA<Border>());
    expect((decoration.border! as Border).top.color, const Color(0xFFE50914));
  });
}
