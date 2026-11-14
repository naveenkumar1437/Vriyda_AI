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
    this.city = '',
    this.region = '',
    required this.students,
    required this.capacity,
    required this.capacityPct,
    required this.collectionPct,
    this.revenue = 0,
    this.outstanding = 0,
    this.attendancePct = 0.0,
    this.examIndex = 0.0,
    this.teachers = 0,
    this.status = 'good',
    Color? dotColor,
  }) : dotColor = dotColor ?? _resolveColor(status, collectionPct);

  static Color _resolveColor(String status, [double collectionPct = 0]) {
    final s = status.toLowerCase();
    if (s == 'good' || s == 'active' || s == 'excellent') {
      return const Color(0xFF10B981); // Emerald Green
    } else if (s == 'warning' || s == 'attention' || s == 'at_risk') {
      return const Color(0xFFF59E0B); // Amber / Orange
    } else if (s == 'danger' || s == 'critical' || s == 'inactive') {
      return const Color(0xFFEF4444); // Red
    } else {
      if (collectionPct >= 75) return const Color(0xFF10B981);
      if (collectionPct >= 50) return const Color(0xFFF59E0B);
      if (collectionPct > 0) return const Color(0xFFEF4444);
      return const Color(0xFF8B5CF6); // Purple
    }
  }

  factory BranchItem.fromJson(Map<String, dynamic> json) {
    final code =
        json['code']?.toString() ?? json['branchCode']?.toString() ?? '';
    final name =
        json['name']?.toString() ?? json['branchName']?.toString() ?? 'Branch';
    final students =
        (json['students'] as num?)?.toInt() ??
        (json['totalStudents'] as num?)?.toInt() ??
        (json['studentCount'] as num?)?.toInt() ??
        0;
    final capacity =
        (json['capacity'] as num?)?.toInt() ??
        (json['totalCapacity'] as num?)?.toInt() ??
        students;
    final capacityPct = json['capacityPct'] != null
        ? (json['capacityPct'] as num).toDouble()
        : (capacity > 0 ? (students / capacity * 100) : 0.0);
    final collectionPct =
        (json['collectionPct'] as num?)?.toDouble() ??
        (json['feeCollectionPct'] as num?)?.toDouble() ??
        0.0;
    final status = json['status']?.toString() ?? 'good';

    return BranchItem(
      id:
          json['id']?.toString() ??
          json['_id']?.toString() ??
          json['branchId']?.toString() ??
          (code.isNotEmpty ? code : name),
      code: code,
      name: name,
      subtitle:
          json['subtitle']?.toString() ??
          (code.isNotEmpty ? '$code · $name' : name),
      city:
          json['city']?.toString() ??
          json['location']?.toString() ??
          json['address']?.toString() ??
          '',
      region: json['region']?.toString() ?? '',
      students: students,
      capacity: capacity,
      capacityPct: double.parse(capacityPct.toStringAsFixed(1)),
      collectionPct: double.parse(collectionPct.toStringAsFixed(1)),
      revenue:
          (json['revenue'] as num?)?.toDouble() ??
          (json['totalRevenue'] as num?)?.toDouble() ??
          0.0,
      outstanding:
          (json['outstanding'] as num?)?.toDouble() ??
          (json['dueFees'] as num?)?.toDouble() ??
          0.0,
      attendancePct:
          (json['attendancePct'] as num?)?.toDouble() ??
          (json['avgAttendance'] as num?)?.toDouble() ??
          0.0,
      examIndex: (json['examIndex'] as num?)?.toDouble() ?? 0.0,
      teachers:
          (json['teachers'] as num?)?.toInt() ??
          (json['totalTeachers'] as num?)?.toInt() ??
          (json['facultyCount'] as num?)?.toInt() ??
          0,
      status: status,
      dotColor: _resolveColor(status, collectionPct),
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

  /// Empty node with 0 branches when API returns no branches or has not loaded yet
  static BranchGroupNode empty({String? orgName}) {
    final title = (orgName != null && orgName.trim().isNotEmpty)
        ? orgName.trim()
        : 'Organization';
    return BranchGroupNode(
      name: title,
      initial: title.isNotEmpty ? title.substring(0, 1).toUpperCase() : 'O',
      totalBranches: 0,
      totalRegions: 0,
      students: 0,
      capacityPct: 0.0,
      collectionPct: 0.0,
      branches: const [],
    );
  }

  /// Alias for backward compatibility that returns an empty tree (no hardcoded data)
  static BranchGroupNode defaultTree({String? orgName}) =>
      empty(orgName: orgName);
}

/// Service to fetch and manage dynamic Branch Tree data directly from APIs
class BranchService {
  /// Fetches branch hierarchy data dynamically from the API.
  /// Strictly returns only what comes from the API — no hardcoded fallback branches.
  static Future<BranchGroupNode> fetchBranchTree({String? orgName}) async {
    final token = await SessionManager.getToken();

    if (token == null || token.isEmpty) {
      return BranchGroupNode.empty(orgName: orgName);
    }

    try {
      // 1. Try ownerBranchTree first
      http.Response? res;
      try {
        res = await http.get(
          Uri.parse(ApiConfig.ownerBranchTree),
          headers: ApiConfig.authHeaders(token),
        );
      } catch (_) {}

      // 2. Fallback to ownerDashboard
      if (res == null || res.statusCode != 200) {
        try {
          res = await http.get(
            Uri.parse(ApiConfig.ownerDashboard),
            headers: ApiConfig.authHeaders(token),
          );
        } catch (_) {}
      }

      // 3. Fallback to ownerBranchHierarchy
      if (res == null || res.statusCode != 200) {
        try {
          res = await http.get(
            Uri.parse(ApiConfig.ownerBranchHierarchy),
            headers: ApiConfig.authHeaders(token),
          );
        } catch (_) {}
      }

      if (res != null && res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return parseFromDashboard(body, orgName: orgName);
        } else if (body is List) {
          return parseFromDashboard({'branches': body}, orgName: orgName);
        }
      } else if (res != null && res.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null) {
            final retryRes = await http.get(
              Uri.parse(ApiConfig.ownerDashboard),
              headers: ApiConfig.authHeaders(newToken),
            );
            if (retryRes.statusCode == 200) {
              final dynamic body = jsonDecode(retryRes.body);
              if (body is Map<String, dynamic>) {
                return parseFromDashboard(body, orgName: orgName);
              } else if (body is List) {
                return parseFromDashboard({'branches': body}, orgName: orgName);
              }
            }
          }
        }
      }
    } catch (_) {
      // Network or parsing failure; return empty node (no hardcoded branches)
    }

    return BranchGroupNode.empty(orgName: orgName);
  }

  /// Parses exclusively the branches returned by the API response.
  /// Does NOT add, merge, or synthesize any mock/hardcoded branch items.
  static BranchGroupNode parseFromDashboard(
    Map<String, dynamic> body, {
    String? orgName,
  }) {
    final data = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    final rawOrgName = data['orgName']?.toString() ?? orgName ?? 'Organization';
    final group = data['group'] as Map<String, dynamic>? ?? {};

    // Extract branches array from API payload
    List<dynamic> rawBranches = [];
    if (data['branches'] is List) {
      rawBranches = data['branches'] as List<dynamic>;
    } else if (body['branches'] is List) {
      rawBranches = body['branches'] as List<dynamic>;
    } else if (data['data'] is List) {
      rawBranches = data['data'] as List<dynamic>;
    } else if (body['data'] is List) {
      rawBranches = body['data'] as List<dynamic>;
    }

    final List<BranchItem> apiBranches = [];
    for (var item in rawBranches) {
      if (item is Map<String, dynamic>) {
        apiBranches.add(BranchItem.fromJson(item));
      }
    }

    final int totalStudents =
        (group['students'] as num?)?.toInt() ??
        apiBranches.fold<int>(0, (sum, b) => sum + b.students);
    final double capacityPct =
        (group['capacityUtil'] as num?)?.toDouble() ??
        (apiBranches.isNotEmpty
            ? apiBranches.fold<double>(0, (sum, b) => sum + b.capacityPct) /
                  apiBranches.length
            : 0.0);
    final double collectionPct =
        (group['collectionPct'] as num?)?.toDouble() ??
        (apiBranches.isNotEmpty
            ? apiBranches.fold<double>(0, (sum, b) => sum + b.collectionPct) /
                  apiBranches.length
            : 0.0);

    final Set<String> regions = apiBranches
        .map((b) => b.region.trim())
        .where((r) => r.isNotEmpty && r != '—' && r != '-')
        .toSet();
    final int totalRegions = regions.isNotEmpty
        ? regions.length
        : (apiBranches.isNotEmpty ? 1 : 0);

    return BranchGroupNode(
      name: rawOrgName,
      initial: rawOrgName.isNotEmpty
          ? rawOrgName.substring(0, 1).toUpperCase()
          : 'O',
      totalBranches: apiBranches.length,
      totalRegions: totalRegions,
      students: totalStudents,
      capacityPct: double.parse(capacityPct.toStringAsFixed(1)),
      collectionPct: double.parse(collectionPct.toStringAsFixed(1)),
      branches: apiBranches,
    );
  }
}
