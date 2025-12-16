import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odyssey/src/features/time_tracker/widgets/confirm_unmark_dialog.dart';

void main() {
  group('ConfirmUnmarkDialog', () {
    testWidgets('displays activity name in message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: 'Test Activity',
                      onConfirm: () {},
                      onCancel: () {},
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

      expect(find.textContaining('Test Activity'), findsOneWidget);
    });

    testWidgets('displays warning question', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: 'Test Activity',
                      onConfirm: () {},
                      onCancel: () {},
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

      expect(find.text('Quer mesmo desmarcar?'), findsOneWidget);
    });

    testWidgets('calls onConfirm when "Sim, desmarcar" is tapped', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: 'Test Activity',
                      onConfirm: () => confirmed = true,
                      onCancel: () {},
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

      await tester.tap(find.text('Sim, desmarcar'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('calls onCancel when "Não" is tapped', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: 'Test Activity',
                      onConfirm: () {},
                      onCancel: () => cancelled = true,
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

      await tester.tap(find.text('Não'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });

    testWidgets('static show method returns true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmUnmarkDialog.show(
                    context: context,
                    activityName: 'Test Activity',
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

      await tester.tap(find.text('Sim, desmarcar'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('static show method returns false on cancel', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmUnmarkDialog.show(
                    context: context,
                    activityName: 'Test Activity',
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

      await tester.tap(find.text('Não'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('truncates long activity names', (tester) async {
      const longName = 'This is a very long activity name that should be truncated';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: longName,
                      onConfirm: () {},
                      onCancel: () {},
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

      // Should find truncated text with "..."
      expect(find.textContaining('...'), findsOneWidget);
    });

    testWidgets('displays undo icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: 'Test Activity',
                      onConfirm: () {},
                      onCancel: () {},
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

      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    });

    testWidgets('dialog cannot be dismissed by tapping outside', (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ConfirmUnmarkDialog(
                      activityName: 'Test Activity',
                      onConfirm: () => confirmed = true,
                      onCancel: () => cancelled = true,
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

      // Try to tap outside dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.text('Quer mesmo desmarcar?'), findsOneWidget);
      expect(confirmed, isFalse);
      expect(cancelled, isFalse);
    });
  });
}
