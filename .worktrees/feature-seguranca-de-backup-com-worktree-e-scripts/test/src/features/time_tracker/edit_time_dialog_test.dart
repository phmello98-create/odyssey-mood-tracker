import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';
import 'package:odyssey/src/features/time_tracker/widgets/edit_time_dialog.dart';

void main() {
  group('EditTimeDialog', () {
    late TimeTrackingRecord testRecord;

    setUp(() {
      testRecord = TimeTrackingRecord(
        id: 'test-id',
        activityName: 'Test Activity',
        iconCode: Icons.timer.codePoint,
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 10, 30),
        duration: const Duration(minutes: 30),
        category: 'Work',
        isCompleted: false,
        colorValue: Colors.blue.value,
      );
    });

    testWidgets('displays initial time from record', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: testRecord,
                      onSave: (_) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Should show 00:30:00 (30 minutes)
      expect(find.text('00'), findsWidgets); // Hours
      expect(find.text('30'), findsOneWidget); // Minutes
    });

    testWidgets('can increment hours', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: testRecord,
                      onSave: (_) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find the first up arrow (hours increment)
      final upArrows = find.byIcon(Icons.keyboard_arrow_up_rounded);
      await tester.tap(upArrows.first);
      await tester.pump();

      // Hours should now be 01
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets('can decrement minutes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: testRecord,
                      onSave: (_) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find the second down arrow (minutes decrement)
      final downArrows = find.byIcon(Icons.keyboard_arrow_down_rounded);
      await tester.tap(downArrows.at(1));
      await tester.pump();

      // Minutes should now be 29
      expect(find.text('29'), findsOneWidget);
    });

    testWidgets('calls onSave with new duration when saving', (tester) async {
      Duration? savedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: testRecord,
                      onSave: (duration) => savedDuration = duration,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Save without changes
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedDuration, equals(const Duration(minutes: 30)));
    });

    testWidgets('quick preset buttons work correctly', (tester) async {
      Duration? savedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: testRecord,
                      onSave: (duration) => savedDuration = duration,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap 1h preset
      await tester.tap(find.text('1h'));
      await tester.pump();

      // Save
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedDuration, equals(const Duration(hours: 1)));
    });

    testWidgets('cancel button closes dialog without saving', (tester) async {
      Duration? savedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: testRecord,
                      onSave: (duration) => savedDuration = duration,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(savedDuration, isNull);
    });

    testWidgets('save button is disabled when duration is zero', (tester) async {
      final zeroRecord = TimeTrackingRecord(
        id: 'test-id',
        activityName: 'Test Activity',
        iconCode: Icons.timer.codePoint,
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 10, 0),
        duration: Duration.zero,
        category: 'Work',
        isCompleted: false,
        colorValue: Colors.blue.value,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: zeroRecord,
                      onSave: (_) {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find the save button and verify it's disabled
      final saveButton = find.widgetWithText(ElevatedButton, 'Salvar');
      final button = tester.widget<ElevatedButton>(saveButton);
      
      expect(button.onPressed, isNull);
    });

    testWidgets('works with completed activities', (tester) async {
      final completedRecord = TimeTrackingRecord(
        id: 'test-id',
        activityName: 'Completed Activity',
        iconCode: Icons.timer.codePoint,
        startTime: DateTime(2024, 1, 1, 10, 0),
        endTime: DateTime(2024, 1, 1, 11, 30),
        duration: const Duration(hours: 1, minutes: 30),
        category: 'Work',
        isCompleted: true,
        colorValue: Colors.green.value,
      );

      Duration? savedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditTimeDialog(
                      record: completedRecord,
                      onSave: (duration) => savedDuration = duration,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Dialog should open and display current time
      expect(find.text('Editar Tempo'), findsOneWidget);
      expect(find.text('01'), findsOneWidget); // 1 hour
      expect(find.text('30'), findsOneWidget); // 30 minutes

      // Should be able to modify and save
      await tester.tap(find.text('2h'));
      await tester.pump();
      
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(savedDuration, equals(const Duration(hours: 2)));
    });
  });
}
