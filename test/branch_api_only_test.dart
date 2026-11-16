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

  test('BranchItem period metrics calculation (MTD, QTD, YTD, FY)', () {
    final branch = BranchItem(
      id: 'b1',
      code: 'TEST-01',
      name: 'Test Branch',
      subtitle: 'CBSE · K-12 · Active',
      city: 'Test City',
      region: 'Test Region',
      students: 100,
      capacity: 120,
      capacityPct: 83.3,
      collectionPct: 80.0,
      revenue: 1200000.0,
      outstanding: 240000.0,
      attendancePct: 95.0,
      examIndex: 90.0,
      teachers: 10,
      status: 'good',
    );

    // YTD baseline
    expect(branch.getCollectionPctForPeriod('YTD'), 80.0);
    expect(branch.getRevenueForPeriod('YTD'), 1200000.0);
    expect(branch.getOutstandingForPeriod('YTD'), 240000.0);

    // MTD
    expect(branch.getCollectionPctForPeriod('MTD'), 89.6); // 80.0 * 1.12 = 89.6
    expect(branch.getRevenueForPeriod('MTD'), 100000.0); // 1200000 / 12
    expect(branch.getOutstandingForPeriod('MTD'), 200000.0 / 10); // 240000 / 12 = 20000

    // QTD
    expect(branch.getCollectionPctForPeriod('QTD'), 84.8); // 80.0 * 1.06 = 84.8
    expect(branch.getRevenueForPeriod('QTD'), closeTo(336000.0, 0.1)); // 1200000 * 0.28
    expect(branch.getOutstandingForPeriod('QTD'), closeTo(67200.0, 0.1)); // 240000 * 0.28

    // FY (projected annual)
    expect(branch.getCollectionPctForPeriod('FY'), 99.0); // capped at 99.0 because 80 * 1.25 = 100 > 99
    expect(branch.getRevenueForPeriod('FY'), closeTo(1380000.0, 0.1)); // 1200000 * 1.15
    expect(branch.getOutstandingForPeriod('FY'), closeTo(96000.0, 0.1)); // 240000 * 0.40
  });

  test('BranchGroupNode period metrics aggregate over child branches', () {
    final b1 = BranchItem(
      id: 'b1',
      code: 'B1',
      name: 'Branch 1',
      subtitle: 'CBSE · K-12',
      city: 'C1',
      region: 'R1',
      students: 100,
      capacity: 100,
      capacityPct: 100,
      collectionPct: 80.0,
      revenue: 1200000.0,
      outstanding: 100000.0,
      attendancePct: 90,
      examIndex: 90,
      teachers: 10,
      status: 'good',
    );
    final b2 = BranchItem(
      id: 'b2',
      code: 'B2',
      name: 'Branch 2',
      subtitle: 'ICSE · K-12',
      city: 'C2',
      region: 'R2',
      students: 100,
      capacity: 100,
      capacityPct: 100,
      collectionPct: 90.0,
      revenue: 2400000.0,
      outstanding: 200000.0,
      attendancePct: 90,
      examIndex: 90,
      teachers: 10,
      status: 'good',
    );

    final group = BranchGroupNode(
      name: 'Test Org',
      initial: 'T',
      totalBranches: 2,
      totalRegions: 2,
      students: 200,
      capacityPct: 100,
      collectionPct: 85.0,
      branches: [b1, b2],
    );

    // Collection % for YTD: (80 + 90) / 2 = 85.0
    expect(group.getCollectionPctForPeriod('YTD'), 85.0);
    // Revenue for YTD: 1200000 + 2400000 = 3600000.0
    expect(group.getRevenueForPeriod('YTD'), 3600000.0);

    // Revenue for MTD: (1200000/12) + (2400000/12) = 100000 + 200000 = 300000.0
    expect(group.getRevenueForPeriod('MTD'), 300000.0);
  });
}
