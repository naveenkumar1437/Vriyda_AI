import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/finance_fee_models.dart';
import 'api_config.dart';
import 'session_manager.dart';

/// Dedicated service for Finance & Fees screen operations.
/// Strictly loads 100% dynamic data from live API endpoints — zero hardcoded fallbacks.
class FinanceService {
  /// Fetches raw JSON from /api/owner-dashboard endpoint.
  static Future<Map<String, dynamic>> fetchRawDashboardJson({
    String period = 'YTD',
    String branch = 'All branches',
  }) async {
    final token = await SessionManager.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final queryParams = <String, String>{'period': period};
    if (branch != 'All branches') {
      queryParams['branch'] = branch;
    }

    final uri = Uri.parse(
      ApiConfig.ownerDashboard,
    ).replace(queryParameters: queryParams);

    final response = await http
        .get(uri, headers: ApiConfig.authHeaders(token))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception('Unexpected API response format');
      }
    } else {
      throw Exception(
        'Failed to load finance data from API (HTTP ${response.statusCode})',
      );
    }
  }

  /// Fetches Finance & Fees data dynamically from the API, mapping into V1 models.
  static Future<FinanceFeeData> fetchFinanceData({
    String period = 'YTD',
    String branch = 'All branches',
  }) async {
    final raw = await fetchRawDashboardJson(period: period, branch: branch);
    return FinanceFeeData.fromDashboardJson(
      raw,
      period: period,
      branchFilter: branch,
    );
  }
}
