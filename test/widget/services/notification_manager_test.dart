import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/services/notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationManager (SnackBars)', () {
    tearDown(() {
      NotificationManager.instance.clearAll();
    });

    testWidgets(
      'queue pending puis flush quand ScaffoldMessengerKey est branchée',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const message = 'Hello pending';

        // 1) Publier avant d’avoir un ScaffoldMessenger => pending.
        NotificationManager.instance.showNotification(message: message);

        // 2) Construire l’app et brancher la key APRÈS le premier pump.
        final messengerKey = GlobalKey<ScaffoldMessengerState>();

        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: messengerKey,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

        // À ce stade, le manager ne connaît toujours pas la key.
        expect(find.text(message), findsNothing);

        NotificationManager.instance.setScaffoldMessengerKey(messengerKey);
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
      },
    );

    testWidgets(
      'SnackBar action d’une notification d’attente appelle le callback',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        var tapped = false;

        NotificationManager.instance.showNotification(
          message: 'Action pending',
          actionLabel: 'OK',
          onAction: () {
            tapped = true;
          },
        );

        final messengerKey = GlobalKey<ScaffoldMessengerState>();

        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: messengerKey,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

        NotificationManager.instance.setScaffoldMessengerKey(messengerKey);
        await tester.pumpAndSettle();

        expect(find.text('OK'), findsOneWidget);

        await tester.ensureVisible(find.text('OK'));
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'quand la key est branchée, showNotification affiche immédiatement',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final messengerKey = GlobalKey<ScaffoldMessengerState>();

        await tester.pumpWidget(
          MaterialApp(
            scaffoldMessengerKey: messengerKey,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

        NotificationManager.instance.setScaffoldMessengerKey(messengerKey);
        await tester.pumpAndSettle();

        const message = 'Hello immediate';
        NotificationManager.instance.showNotification(message: message);
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
      },
    );
  });
}
