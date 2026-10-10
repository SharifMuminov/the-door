import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_door/app/app.dart';
import 'package:the_door/core/utils/audio_manager.dart';
import 'package:the_door/core/utils/game_storage.dart';
import 'package:the_door/core/utils/haptics.dart';

void main() {
  testWidgets(
    'first launch: pick Uzbek → menu → O‘YNASH → XONA 01 → read the note',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // No audio init: the manager stays silent, exactly like a device
      // without sound files.
      await tester.pumpWidget(
        TheDoorApp(
          storage: GameStorage.memory(),
          audio: AudioManager(),
          haptics: Haptics(enabled: false),
        ),
      );

      expect(find.text('TILNI TANLANG'), findsOneWidget);
      await tester.tap(find.text('O‘ZBEKCHA'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('QULOQCHIN TAVSIYA ETILADI'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('THE DOOR'), findsOneWidget);
      expect(find.text('O‘YNASH'), findsOneWidget);

      await tester.tap(find.text('O‘YNASH'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      // The intro card tells one line of the story; a tap hurries it on.
      expect(
        find.text('Bu yerda qanday uxlab qolganingizni eslamaysiz.'),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(195, 420));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('XONA 01'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Eslatma'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('BIRINCHI QOIDA'), findsOneWidget);

      await tester.tap(find.text('YOPISH'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('BIRINCHI QOIDA'), findsNothing);

      // Leave the game so every timer is disposed.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
