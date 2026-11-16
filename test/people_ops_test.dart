import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vriyda_ai/screens/people_ops_view.dart';

void main() {
  testWidgets('PeopleOpsView renders Resources header, 6 KPI cards, and Branch Table', (tester) async {
    const mockBranches = [
      {
        'id': 1,
        'name': 'Steel Plant Branch',
        'resources': {
          'classrooms': 4,
          'totalSeats': 155,
          'digitalClassrooms': 0,
          'scienceLabs': 0,
          'computerLabs': 0,
          'buses': 7,
          'busRoutes': 6,
          'busSeats': 315,
          'hostelBeds': 40,
          'hostelBedsOccupied': 12,
          'libraryCopies': 104,
        },
      },
      {
        'id': 2,
        'name': 'Gachibowli Campus',
        'resources': {},
      },
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeopleOpsView(branches: mockBranches),
          ),
        ),
      ),
    );

    // Verify Header
    expect(find.text('Resources'), findsOneWidget);
    expect(find.text('Resources by branch'), findsOneWidget);

    // Verify 6 KPI Card labels
    expect(find.text('CLASSROOMS'), findsOneWidget);
    expect(find.text('DIGITAL CLASSROOMS'), findsOneWidget);
    expect(find.text('LABS'), findsOneWidget);
    expect(find.text('BUSES'), findsOneWidget);
    expect(find.text('HOSTEL BEDS'), findsOneWidget);
    expect(find.text('LIBRARY COPIES'), findsOneWidget);

    // Verify key counts from web screens
    expect(find.text('4'), findsWidgets);
    expect(find.text('7'), findsWidgets);
    expect(find.text('40'), findsWidgets);
    expect(find.text('104'), findsWidgets);
  });
}
