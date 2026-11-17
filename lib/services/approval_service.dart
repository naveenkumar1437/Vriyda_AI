import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_manager.dart';

/// Service for handling Chairman Approvals queue
class ApprovalService {
  /// Submit decision for an approval item (approved / rejected)
  static Future<bool> decideApproval({
    required String id,
    required String branch,
    required String type,
    required String decision, // 'approved' or 'rejected'
    String? note,
  }) async {
    final token = await SessionManager.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.ownerApprovals),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'id': id,
          'branch': branch,
          'type': type,
          'decision': decision,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ok'] == true || data['success'] == true;
      }
    } catch (_) {}

    return false;
  }
}
