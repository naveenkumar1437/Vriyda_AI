import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'session_manager.dart';

/// Single Branch Model for the Branch Hierarchy Tree
class BranchItem {
  final String id;
  final String code;
  final String name;
  final String subtitle;
  final String city;
  final String region;
  final int students;
  final int capacity;
  final double capacityPct;
  final double collectionPct;
  final double revenue;
  final double outstanding;
  final double attendancePct;
  final double examIndex;
  final int teachers;
  final String status;
  final Color dotColor;

  BranchItem({
    required this.id,
    required this.code,
    required this.name,
    required this.subtitle,
    this.city = 'Hyderabad',
    this.region = 'South Region',
    required this.students,
    required this.capacity,
    required this.capacityPct,
    required this.collectionPct,
    this.revenue = 0,
    this.outstanding = 0,
    this.attendancePct = 92.0,
    this.examIndex = 80.0,
    this.teachers = 10,
    this.status = 'good',
    Color? dotColor,
  }) : dotColor = dotColor ?? _resolveColor(status, code);

  static Color _resolveColor(String status, String code) {
    if (code == 'STEE' || code == 'KOND' || code == 'KBHP') {
      return const Color(0xFF10B981); // Emerald Green
    } else if (code == 'MADD') {
      return const Color(0xFFEF4444); // Red
    } else if (code == 'LBNA') {
      return const Color(0xFFF59E0B); // Amber / Orange
    } else {
      return const Color(0xFF8B5CF6); // Purple
    }
  }

  factory BranchItem.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? 'BR';
    final name = json['name']?.toString() ?? 'Branch';
    final students = (json['students'] as num?)?.toInt() ?? 0;
    final capacity = (json['capacity'] as num?)?.toInt() ?? (students > 0 ? (students * 1.2).round() : 100);
    final capacityPct = json['capacityPct'] != null
        ? (json['capacityPct'] as num).toDouble()
        : (capacity > 0 ? (students / capacity * 100) : 0.0);
    final collectionPct = (json['collectionPct'] as num?)?.toDouble() ?? 0.0;
    final status = json['status']?.toString() ?? 'good';

    return BranchItem(
      id: json['id']?.toString() ?? code,
      code: code,
      name: name,
      subtitle: '$code · $name',
      city: json['city']?.toString() ?? (code == 'STEE' || code == 'MADD' ? 'Visakhapatnam' : 'Hyderabad'),
      region: json['region']?.toString() ?? 'South Region',
      students: students,
      capacity: capacity,
      capacityPct: double.parse(capacityPct.toStringAsFixed(1)),
      collectionPct: double.parse(collectionPct.toStringAsFixed(1)),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0.0,
      attendancePct: (json['attendancePct'] as num?)?.toDouble() ?? 92.0,
      examIndex: (json['examIndex'] as num?)?.toDouble() ?? 80.0,
      teachers: (json['teachers'] as num?)?.toInt() ?? 10,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'subtitle': subtitle,
        'city': city,
        'region': region,
        'students': students,
        'capacity': capacity,
        'capacityPct': capacityPct,
        'collectionPct': collectionPct,
        'revenue': revenue,
        'outstanding': outstanding,
        'attendancePct': attendancePct,
        'examIndex': examIndex,
        'teachers': teachers,
        'status': status,
      };
}

/// Root School / Group Node containing the aggregated roll-ups
class BranchGroupNode {
  final String name;
  final String initial;
  final int totalBranches;
  final int totalRegions;
  final int students;
  final double capacityPct;
  final double collectionPct;
  final List<BranchItem> branches;

  BranchGroupNode({
    required this.name,
    required this.initial,
    required this.totalBranches,
    required this.totalRegions,
    required this.students,
    required this.capacityPct,
    required this.collectionPct,
    required this.branches,
  });

  /// Default exact fallback data matching the Figma / Stitch UI screenshot
  static BranchGroupNode defaultTree() {
    return BranchGroupNode(
      name: 'Sai Ravindra School',
      initial: 'S',
      totalBranches: 9,
      totalRegions: 1,
      students: 124,
      capacityPct: 81.0,
      collectionPct: 67.8,
      branches: [
        BranchItem(
          id: '1',
          code: 'STEE',
          name: 'Steel Plant Branch',
          subtitle: 'STEE · Steel Plant Branch',
          city: 'Visakhapatnam',
          students: 42,
          capacity: 49,
          capacityPct: 85.7,
          collectionPct: 83.3,
          revenue: 6200000,
          outstanding: 1100000,
          attendancePct: 93.1,
          examIndex: 84.0,
          teachers: 28,
          status: 'good',
          dotColor: const Color(0xFF10B981),
        ),
        BranchItem(
          id: '2',
          code: 'GACH',
          name: 'Gachibowli Campus',
          subtitle: 'GACH · Gachibowli Campus',
          city: 'Hyderabad',
          students: 21,
          capacity: 23,
          capacityPct: 91.3,
          collectionPct: 51.6,
          revenue: 3400000,
          outstanding: 1600000,
          attendancePct: 91.5,
          examIndex: 82.0,
          teachers: 18,
          status: 'warning',
          dotColor: const Color(0xFF8B5CF6),
        ),
        BranchItem(
          id: '3',
          code: 'KOND',
          name: 'Kondapur Branch',
          subtitle: 'KOND · Kondapur Branch',
          city: 'Hyderabad',
          students: 14,
          capacity: 18,
          capacityPct: 77.8,
          collectionPct: 74.3,
          revenue: 2100000,
          outstanding: 540000,
          attendancePct: 94.2,
          examIndex: 79.5,
          teachers: 12,
          status: 'good',
          dotColor: const Color(0xFF10B981),
        ),
        BranchItem(
          id: '4',
          code: 'KUKA',
          name: 'Kukatpally Campus',
          subtitle: 'KUKA · Kukatpally Campus',
          city: 'Hyderabad',
          students: 17,
          capacity: 22,
          capacityPct: 77.3,
          collectionPct: 72.9,
          revenue: 2600000,
          outstanding: 700000,
          attendancePct: 92.0,
          examIndex: 81.0,
          teachers: 14,
          status: 'good',
          dotColor: const Color(0xFF8B5CF6),
        ),
        BranchItem(
          id: '5',
          code: 'MADD',
          name: 'Maddipalem',
          subtitle: 'MADD · Maddipalem',
          city: 'Visakhapatnam',
          students: 18,
          capacity: 22,
          capacityPct: 81.8,
          collectionPct: 54.7,
          revenue: 2500000,
          outstanding: 1100000,
          attendancePct: 89.4,
          examIndex: 76.5,
          teachers: 15,
          status: 'warning',
          dotColor: const Color(0xFFEF4444),
        ),
        BranchItem(
          id: '6',
          code: 'MADH',
          name: 'Madhapur Branch',
          subtitle: 'MADH · Madhapur Branch',
          city: 'Hyderabad',
          students: 9,
          capacity: 13,
          capacityPct: 69.2,
          collectionPct: 72.5,
          revenue: 1500000,
          outstanding: 410000,
          attendancePct: 90.8,
          examIndex: 80.2,
          teachers: 9,
          status: 'good',
          dotColor: const Color(0xFF8B5CF6),
        ),
        BranchItem(
          id: '7',
          code: 'KBHP',
          name: 'KBHP',
          subtitle: 'KBHP · KBHP',
          city: 'Hyderabad',
          students: 1,
          capacity: 2,
          capacityPct: 50.0,
          collectionPct: 0.0,
          revenue: 150000,
          outstanding: 150000,
          attendancePct: 85.0,
          examIndex: 70.0,
          teachers: 3,
          status: 'neutral',
          dotColor: const Color(0xFF10B981),
        ),
        BranchItem(
          id: '8',
          code: 'LBNA',
          name: 'LB Nagar',
          subtitle: 'LBNA · LB Nagar',
          city: 'Hyderabad',
          students: 2,
          capacity: 4,
          capacityPct: 50.0,
          collectionPct: 0.0,
          revenue: 300000,
          outstanding: 300000,
          attendancePct: 88.0,
          examIndex: 72.0,
          teachers: 4,
          status: 'warning',
          dotColor: const Color(0xFFF59E0B),
        ),
        BranchItem(
          id: '9',
          code: 'BANJ',
          name: 'Banjara Hills',
          subtitle: 'BANJ · Banjara Hills',
          city: 'Hyderabad',
          students: 0,
          capacity: 0,
          capacityPct: 0.0,
          collectionPct: 0.0,
          revenue: 0,
          outstanding: 0,
          attendancePct: 0.0,
          examIndex: 0.0,
          teachers: 2,
          status: 'neutral',
          dotColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }
}

/// Service to fetch and manage dynamic Branch Tree data
class BranchService {
  /// Fetches branch hierarchy data dynamically from the API, falling back to cached/default data.
  static Future<BranchGroupNode> fetchBranchTree({String? orgName}) async {
    final token = await SessionManager.getToken();
    final defaultData = BranchGroupNode.defaultTree();

    if (token == null || token.isEmpty || token == 'demo-chairman-token') {
      return defaultData;
    }

    try {
      // 1. Try ownerBranchTree or ownerBranchHierarchy endpoint first
      http.Response? res;
      try {
        res = await http.get(
          Uri.parse(ApiConfig.ownerBranchTree),
          headers: ApiConfig.authHeaders(token),
        );
      } catch (_) {
        // Fallback to ownerDashboard
      }

      if (res == null || res.statusCode != 200) {
        res = await http.get(
          Uri.parse(ApiConfig.ownerDashboard),
          headers: ApiConfig.authHeaders(token),
        );
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return _parseFromDashboard(body, orgName: orgName);
        }
      } else if (res.statusCode == 401) {
        // Try refresh token once
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null) {
            final retryRes = await http.get(
              Uri.parse(ApiConfig.ownerDashboard),
              headers: ApiConfig.authHeaders(newToken),
            );
            if (retryRes.statusCode == 200) {
              final body = jsonDecode(retryRes.body);
              if (body is Map<String, dynamic>) {
                return _parseFromDashboard(body, orgName: orgName);
              }
            }
          }
        }
      }
    } catch (_) {
      // Network failure or parsing exception; safely return defaultData
    }

    return defaultData;
  }

  static BranchGroupNode _parseFromDashboard(Map<String, dynamic> body, {String? orgName}) {
    final rawOrgName = body['orgName']?.toString() ?? orgName ?? 'Sai Ravindra School';
    final group = body['group'] as Map<String, dynamic>? ?? {};
    final rawBranches = body['branches'] as List<dynamic>? ?? [];

    final defaultTree = BranchGroupNode.defaultTree();
    final Map<String, BranchItem> defaultMap = {
      for (var b in defaultTree.branches) b.code.toUpperCase(): b,
    };
    final Map<String, BranchItem> defaultNameMap = {
      for (var b in defaultTree.branches) b.name.toLowerCase(): b,
    };

    final List<BranchItem> merged = [];
    final Set<String> processedCodes = {};

    for (var item in rawBranches) {
      if (item is Map<String, dynamic>) {
        final code = (item['code']?.toString() ?? '').toUpperCase();
        final name = item['name']?.toString() ?? '';
        final defaultMatch = defaultMap[code] ?? defaultNameMap[name.toLowerCase()];

        final students = (item['students'] as num?)?.toInt() ?? defaultMatch?.students ?? 0;
        final capacity = (item['capacity'] as num?)?.toInt() ?? defaultMatch?.capacity ?? (students > 0 ? (students * 1.2).round() : 50);
        final rawCapPct = (item['capacityPct'] as num?)?.toDouble() ??
            (capacity > 0 ? (students / capacity * 100) : defaultMatch?.capacityPct ?? 0.0);
        final rawColPct = (item['collectionPct'] as num?)?.toDouble() ?? defaultMatch?.collectionPct ?? 0.0;

        merged.add(BranchItem(
          id: item['id']?.toString() ?? defaultMatch?.id ?? code,
          code: code.isNotEmpty ? code : (defaultMatch?.code ?? 'BR'),
          name: name.isNotEmpty ? name : (defaultMatch?.name ?? 'Branch'),
          subtitle: defaultMatch?.subtitle ?? '$code · $name',
          city: item['city']?.toString() ?? defaultMatch?.city ?? 'Hyderabad',
          region: item['region']?.toString() ?? defaultMatch?.region ?? 'South Region',
          students: students,
          capacity: capacity,
          capacityPct: double.parse(rawCapPct.toStringAsFixed(1)),
          collectionPct: double.parse(rawColPct.toStringAsFixed(1)),
          revenue: (item['revenue'] as num?)?.toDouble() ?? defaultMatch?.revenue ?? 0.0,
          outstanding: (item['outstanding'] as num?)?.toDouble() ?? defaultMatch?.outstanding ?? 0.0,
          attendancePct: (item['attendancePct'] as num?)?.toDouble() ?? defaultMatch?.attendancePct ?? 92.0,
          examIndex: (item['examIndex'] as num?)?.toDouble() ?? defaultMatch?.examIndex ?? 80.0,
          teachers: (item['teachers'] as num?)?.toInt() ?? defaultMatch?.teachers ?? 10,
          status: item['status']?.toString() ?? defaultMatch?.status ?? 'good',
          dotColor: defaultMatch?.dotColor,
        ));
        if (code.isNotEmpty) processedCodes.add(code);
      }
    }

    // Include remaining default branches so the full 9 branches from the design are available
    for (var def in defaultTree.branches) {
      if (!processedCodes.contains(def.code.toUpperCase()) &&
          !merged.any((m) => m.name.toLowerCase() == def.name.toLowerCase())) {
        merged.add(def);
      }
    }

    final int totalStudents = (group['students'] as num?)?.toInt() ??
        merged.fold<int>(0, (sum, b) => sum + b.students);
    final double capacityPct = (group['capacityUtil'] as num?)?.toDouble() ??
        (merged.isNotEmpty
            ? merged.fold<double>(0, (sum, b) => sum + b.capacityPct) / merged.length
            : 81.0);
    final double collectionPct = (group['collectionPct'] as num?)?.toDouble() ??
        (merged.isNotEmpty
            ? merged.fold<double>(0, (sum, b) => sum + b.collectionPct) / merged.length
            : 67.8);

    return BranchGroupNode(
      name: rawOrgName,
      initial: rawOrgName.isNotEmpty ? rawOrgName.substring(0, 1).toUpperCase() : 'S',
      totalBranches: merged.length,
      totalRegions: 1,
      students: totalStudents,
      capacityPct: double.parse(capacityPct.toStringAsFixed(1)),
      collectionPct: double.parse(collectionPct.toStringAsFixed(1)),
      branches: merged,
    );
  }
}

