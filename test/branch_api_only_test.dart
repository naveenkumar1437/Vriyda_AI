import 'package:flutter_test/flutter_test.dart';
import 'package:vriyda_ai/services/branch_service.dart';

void main() {
  test('BranchService parses only API branches without hardcoded defaults', () {
    final apiResponse = {
      'orgName': 'Vriyda International School',
      'group': {
        'students': 500,
        'capacity': 600,
        'capacityUtil': 83.3,
        'collectionPct': 91.5,
      },
      'branches': [
        {
          'id': 'b101',
          'code': 'HYD-01',
          'name': 'Hyderabad Central Campus',
          'city': 'Hyderabad',
          'region': 'Telangana Region',
          'students': 300,
          'capacity': 350,
          'capacityPct': 85.7,
          'collectionPct': 94.0,
          'revenue': 4500000,
          'outstanding': 200000,
          'attendancePct': 96.5,
          'examIndex': 88.0,
          'teachers': 25,
          'status': 'good',
        },
        {
          'id': 'b102',
          'code': 'BLR-02',
          'name': 'Bangalore Tech Campus',
          'city': 'Bengaluru',
          'region': 'Karnataka Region',
          'students': 200,
          'capacity': 250,
          'capacityPct': 80.0,
          'collectionPct': 89.0,
          'revenue': 3000000,
          'outstanding': 350000,
          'attendancePct': 91.0,
          'examIndex': 82.5,
          'teachers': 18,
          'status': 'warning',
        },
      ],
    };

    final tree = BranchService.parseFromDashboard(apiResponse);

    // Verify it contains ONLY the 2 branches returned by the API
    expect(tree.branches.length, 2);
    expect(tree.totalBranches, 2);
    expect(tree.name, 'Vriyda International School');
    expect(tree.branches[0].name, 'Hyderabad Central Campus');
    expect(tree.branches[0].code, 'HYD-01');
    expect(tree.branches[0].city, 'Hyderabad');
    expect(tree.branches[0].students, 300);
    expect(tree.branches[1].name, 'Bangalore Tech Campus');
    expect(tree.branches[1].code, 'BLR-02');
    expect(tree.branches[1].students, 200);

    // Verify NO hardcoded branches like "Steel Plant Branch" or "Maddipalem" exist
    expect(tree.branches.any((b) => b.name == 'Steel Plant Branch'), isFalse);
    expect(tree.branches.any((b) => b.name == 'Maddipalem'), isFalse);
    expect(tree.branches.any((b) => b.name == 'Banjara Hills'), isFalse);
  });
}
