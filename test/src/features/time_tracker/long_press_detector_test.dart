import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odyssey/src/utils/widgets/long_press_detector.dart';

void main() {
  group('LongPressDetector', () {
    testWidgets('triggers onTap when released before threshold', (tester) async {
      bool tapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LongPressDetector(
              threshold: const Duration(milliseconds: 450),
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
              enableHapticFeedback: false,
              enableVisualFeedback: false,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Tap quickly (before 450ms threshold)
      await tester.tap(find.byType(Container).first);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
      expect(longPressed, isFalse);
    });

    testWidgets('triggers onLongPress after threshold', (tester) async {
      bool tapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LongPressDetector(
              threshold: const Duration(milliseconds: 450),
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
              enableHapticFeedback: false,
              enableVisualFeedback: false,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Long press (after 450ms threshold)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Container).first),
      );
      
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      expect(longPressed, isTrue);
      expect(tapped, isFalse);
    });

    testWidgets('cancels long press when dragging beyond threshold', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LongPressDetector(
              threshold: const Duration(milliseconds: 450),
              dragCancelDistance: 8.0,
              onLongPress: () => longPressed = true,
              enableHapticFeedback: false,
              enableVisualFeedback: false,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Start press and drag more than 8px
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Container).first),
      );
      
      // Move more than 8px
      await gesture.moveBy(const Offset(15, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      // Long press should be cancelled due to drag
      expect(longPressed, isFalse);
    });

    testWidgets('does not cancel when drag is within threshold', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LongPressDetector(
              threshold: const Duration(milliseconds: 450),
              dragCancelDistance: 8.0,
              onLongPress: () => longPressed = true,
              enableHapticFeedback: false,
              enableVisualFeedback: false,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Start press and drag less than 8px
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Container).first),
      );
      
      // Move less than 8px
      await gesture.moveBy(const Offset(5, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      // Long press should still trigger
      expect(longPressed, isTrue);
    });

    testWidgets('applies visual feedback scale animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LongPressDetector(
              threshold: const Duration(milliseconds: 450),
              enableHapticFeedback: false,
              enableVisualFeedback: true,
              onLongPress: () {},
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Find LongPressDetector which wraps child in Transform when visual feedback is enabled
      expect(find.byType(LongPressDetector), findsOneWidget);
      // Transform widgets are present (at least one for our scale animation)
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('uses custom threshold duration', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LongPressDetector(
              threshold: const Duration(milliseconds: 200),
              onLongPress: () => longPressed = true,
              enableHapticFeedback: false,
              enableVisualFeedback: false,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      // Press for 250ms (longer than custom 200ms threshold)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Container).first),
      );
      
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.up();
      await tester.pump();

      expect(longPressed, isTrue);
    });
  });
}
