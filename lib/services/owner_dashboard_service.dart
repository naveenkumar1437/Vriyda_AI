import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/users_directory_data.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'session_manager.dart';

/// Dedicated service for Chairman / Owner Dashboard APIs:
/// - GET /api/owner-dashboard/users-directory
/// - GET /api/owner-dashboard/attendance-directory?date=YYYY-MM-DD
/// - GET /api/owner-dashboard/class-performance
/// - GET /api/owner-dashboard/payroll
class OwnerDashboardService {
  /// 1. GET /api/owner-dashboard/users-directory
  /// Fetches live users directory for all 6 roles directly from ERPNext
  static Future<List<UserDirectoryItem>> getUsersDirectory({
    String? branch,
    String? role,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return const [];

    final queryParams = <String, String>{};
    if (branch != null && branch.isNotEmpty && branch != 'all' && branch != 'All branches') {
      queryParams['branch'] = branch;
    }
    if (role != null && role.isNotEmpty && role != 'all') {
      queryParams['role'] = role;
    }

    final uri = Uri.parse(ApiConfig.ownerUsersDirectory).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      var res = await http.get(uri, headers: ApiConfig.authHeaders(token));

      if (res.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            res = await http.get(uri, headers: ApiConfig.authHeaders(newToken));
          }
        }
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        List<dynamic>? rawList;

        if (body is List) {
          rawList = body;
        } else if (body is Map<String, dynamic>) {
          if (body['data'] is List) {
            rawList = body['data'] as List;
          } else if (body['users'] is List) {
            rawList = body['users'] as List;
          } else if (body['data'] is Map<String, dynamic>) {
            // Aggregated by role or branches
            final dataMap = body['data'] as Map<String, dynamic>;
            rawList = [];
            for (final entry in dataMap.values) {
              if (entry is List) {
                rawList.addAll(entry);
              }
            }
          }
        }

        if (rawList != null) {
          return rawList
              .whereType<Map<String, dynamic>>()
              .map((item) => UserDirectoryItem.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching users directory: $e');
    }

    return const [];
  }

  /// 2. GET /api/owner-dashboard/attendance-directory?date=YYYY-MM-DD
  /// Fetches live daily attendance per student and staff member
  static Future<Map<String, dynamic>?> getAttendanceDirectory({
    required String date,
    String? branch,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return null;

    final queryParams = <String, String>{'date': date};
    if (branch != null && branch.isNotEmpty && branch != 'all' && branch != 'All branches') {
      queryParams['branch'] = branch;
    }

    final uri = Uri.parse(ApiConfig.ownerAttendanceDirectory).replace(
      queryParameters: queryParams,
    );

    try {
      var res = await http.get(uri, headers: ApiConfig.authHeaders(token));

      if (res.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            res = await http.get(uri, headers: ApiConfig.authHeaders(newToken));
          }
        }
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance directory: $e');
    }

    return null;
  }

  /// 3. GET /api/owner-dashboard/class-performance
  /// Fetches academic marks distribution by class/exam
  static Future<Map<String, dynamic>?> getClassPerformance({
    String? className,
    String? examId,
    String? branch,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return null;

    final queryParams = <String, String>{};
    if (className != null && className.isNotEmpty) queryParams['class'] = className;
    if (examId != null && examId.isNotEmpty) queryParams['exam'] = examId;
    if (branch != null && branch.isNotEmpty && branch != 'all' && branch != 'All branches') {
      queryParams['branch'] = branch;
    }

    final uri = Uri.parse(ApiConfig.ownerClassPerformance).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      var res = await http.get(uri, headers: ApiConfig.authHeaders(token));

      if (res.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            res = await http.get(uri, headers: ApiConfig.authHeaders(newToken));
          }
        }
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('Error fetching class performance: $e');
    }

    return null;
  }

  /// 4. GET /api/owner-dashboard/payroll
  /// Fetches staff payroll aggregated by month and branch
  static Future<Map<String, dynamic>?> getPayrollData({
    String? month,
    String? branch,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return null;

    final queryParams = <String, String>{};
    if (month != null && month.isNotEmpty) queryParams['month'] = month;
    if (branch != null && branch.isNotEmpty && branch != 'all' && branch != 'All branches') {
      queryParams['branch'] = branch;
    }

    final uri = Uri.parse(ApiConfig.ownerPayroll).replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      var res = await http.get(uri, headers: ApiConfig.authHeaders(token));

      if (res.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          final newToken = await SessionManager.getToken();
          if (newToken != null && newToken.isNotEmpty) {
            res = await http.get(uri, headers: ApiConfig.authHeaders(newToken));
          }
        }
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return body;
        }
      }
    } catch (e) {
      debugPrint('Error fetching payroll data: $e');
    }

    return null;
  }
}
