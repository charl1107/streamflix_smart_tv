import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamflix_tv/services/vidnest_service.dart';
import 'package:streamflix_tv/widgets/tv_server_switcher_modal.dart';

void main() {
  group('TvServerSwitcherModal Widget & D-Pad Tests', () {
    testWidgets('Renders all Vidnest servers with proper badges', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvServerSwitcherModal(
              activeServerId: 'lamda',
              onServerSelected: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title and instructions
      expect(find.text('Select Streaming Server'), findsOneWidget);
      expect(find.textContaining('D-Pad to navigate'), findsOneWidget);

      // Verify all servers are listed
      for (final server in VidnestService.servers) {
        expect(find.text(server.name), findsOneWidget);
        expect(find.text(server.badge), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Selecting a server card triggers callback', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      VidnestServer? selectedServer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvServerSwitcherModal(
              activeServerId: 'lamda',
              onServerSelected: (s) => selectedServer = s,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'PrimeSrc' server
      final primeSrcFinder = find.text('PrimeSrc');
      expect(primeSrcFinder, findsOneWidget);

      await tester.tap(primeSrcFinder);
      await tester.pumpAndSettle();

      expect(selectedServer, isNotNull);
      expect(selectedServer!.id, 'primesrc');
    });

    testWidgets('Escape / Back key triggers dismiss callback', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvServerSwitcherModal(
              activeServerId: 'gama',
              onServerSelected: (_) {},
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Send Escape key event (standard TV Back / Escape)
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });
  });
}
