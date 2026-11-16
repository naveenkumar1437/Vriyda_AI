import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/live_dashboard_payload.dart';
import '../models/finance_fee_models.dart';
import 'api_config.dart';
import 'session_manager.dart';

/// Dedicated service for Finance & Fees screen operations.
/// Follows existing networking pattern without modifying other shared services.
class FinanceService {
  /// Fetches Finance & Fees data dynamically from the API, mapping into V1 models.
  static Future<FinanceFeeData> fetchFinanceData({
    String period = 'YTD',
    String branch = 'All branches',
  }) async {
    final token = await SessionManager.getToken();

    if (token == null || token.isEmpty) {
      // Offline / Unauthenticated fallback
      return FinanceFeeData.fromDashboardJson(
        kDefaultLiveDashboardData,
        period: period,
        branchFilter: branch,
      );
    }

    try {
      final uri = Uri.parse('${ApiConfig.ownerDashboard}?period=$period');
      final response = await http
          .get(uri, headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return FinanceFeeData.fromDashboardJson(
            decoded,
            period: period,
            branchFilter: branch,
          );
        }
      }
    } catch (_) {
      // Network failure, timeout, or server unavailable
    }

    // Graceful fallback to default live data payload
    return FinanceFeeData.fromDashboardJson(
      kDefaultLiveDashboardData,
      period: period,
      branchFilter: branch,
    );
  }
}
