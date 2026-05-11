import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';

void main() {
  testWidgets('LaunchStatusDropdown tolerates duplicate status values',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaunchStatusDropdown(
            value: 'Planned',
            items: const ['Planned', 'Planned', 'In Progress', 'Complete'],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Planned'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Planned'), findsNWidgets(2));
  });

  testWidgets('LaunchStatusDropdown keeps saved legacy values selectable',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaunchStatusDropdown(
            value: 'Planned',
            items: const ['Open', 'Mitigated', 'Closed'],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Planned'), findsOneWidget);
  });
}
