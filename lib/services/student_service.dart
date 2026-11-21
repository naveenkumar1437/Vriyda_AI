import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'session_manager.dart';

/// Model representing a student in the directory / lookup
class StudentLookupItem {
  final String id;
  final String name;
  final String branch;
  final String klass;
  final String section;

  const StudentLookupItem({
    required this.id,
    required this.name,
    required this.branch,
    required this.klass,
    required this.section,
  });

  factory StudentLookupItem.fromJson(Map<String, dynamic> json) {
    return StudentLookupItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      klass: json['klass']?.toString() ?? json['class']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
    );
  }
}

/// Model for the detailed Student Card / Snippet & Garuda AI Snapshot
class StudentSnippetData {
  final String id;
  final String name;
  final String klass;
  final String section;
  final String branch;
  final String? gender;
  final int attendancePct;
  final int examAvg;
  final bool passed;
  final num billed;
  final num due;
  final List<String> bullets;
  final String ai; // 'garuda' | 'snapshot' | 'busy'
  final String? note;

  const StudentSnippetData({
    required this.id,
    required this.name,
    required this.klass,
    required this.section,
    required this.branch,
    this.gender,
    required this.attendancePct,
    required this.examAvg,
    required this.passed,
    required this.billed,
    required this.due,
    required this.bullets,
    required this.ai,
    this.note,
  });

  bool get isGarudaAi => ai == 'garuda';

  factory StudentSnippetData.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawBullets = json['bullets'] as List<dynamic>? ?? [];

    final bulletsList = rawBullets.map((b) => b.toString()).toList();

    return StudentSnippetData(
      id: profile['id']?.toString() ?? '',
      name: profile['name']?.toString() ?? '',
      klass: profile['klass']?.toString() ?? stats['klass']?.toString() ?? '',
      section: profile['section']?.toString() ?? stats['section']?.toString() ?? '',
      branch: profile['branch']?.toString() ?? stats['branch']?.toString() ?? '',
      gender: profile['gender']?.toString(),
      attendancePct: (stats['attendancePct'] as num?)?.toInt() ?? 0,
      examAvg: (stats['examAvg'] as num?)?.toInt() ?? 0,
      passed: stats['passed'] == true,
      billed: (stats['billed'] as num?) ?? 0,
      due: (stats['due'] as num?) ?? 0,
      bullets: bulletsList,
      ai: json['ai']?.toString() ?? 'snapshot',
      note: json['note']?.toString(),
    );
  }
}

/// Service handling Student Lookup directory and Garuda AI 360 Snippet
class StudentService {
  /// 1. Fetch all students across branches for filtering & lookup
  /// API 14: GET /owner-dashboard/students
  static Future<List<StudentLookupItem>> getStudents() async {
    final token = await SessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.ownerStudents),
          headers: ApiConfig.authHeaders(token),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map && data['students'] is List) {
            final list = (data['students'] as List)
                .map((item) => StudentLookupItem.fromJson(item as Map<String, dynamic>))
                .toList();
            if (list.isNotEmpty) return list;
          }
        } else if (res.statusCode == 401) {
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            final newToken = await SessionManager.getToken();
            if (newToken != null) {
              final retryRes = await http.get(
                Uri.parse(ApiConfig.ownerStudents),
                headers: ApiConfig.authHeaders(newToken),
              );
              if (retryRes.statusCode == 200) {
                final retryData = jsonDecode(retryRes.body);
                if (retryData is Map && retryData['students'] is List) {
                  return (retryData['students'] as List)
                      .map((item) => StudentLookupItem.fromJson(item as Map<String, dynamic>))
                      .toList();
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return const <StudentLookupItem>[];
  }

  /// 2. Fetch standard student snapshot (Fast response)
  /// API 15: `GET /owner-dashboard/student-snippet?student=<id>`
  static Future<StudentSnippetData?> getStudentSnippet(String studentId) async {
    final token = await SessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final url = '${ApiConfig.ownerStudentSnippet}?student=$studentId';
        final res = await http.get(
          Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map<String, dynamic>) {
            return StudentSnippetData.fromJson(body);
          }
        } else if (res.statusCode == 401) {
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            final newToken = await SessionManager.getToken();
            if (newToken != null) {
              final retryRes = await http.get(
                Uri.parse(url),
                headers: ApiConfig.authHeaders(newToken),
              );
              if (retryRes.statusCode == 200) {
                final retryBody = jsonDecode(retryRes.body);
                if (retryBody is Map<String, dynamic>) {
                  return StudentSnippetData.fromJson(retryBody);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// 3. Fetch Garuda AI student summary (Rich AI response)
  /// API 16: `GET /owner-dashboard/student-snippet/ai?student=<id>`
  static Future<StudentSnippetData?> getStudentAiSnippet(String studentId) async {
    final token = await SessionManager.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final url = '${ApiConfig.ownerStudentAiSnippet}?student=$studentId';
        final res = await http.get(
          Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map<String, dynamic>) {
            return StudentSnippetData.fromJson(body);
          }
        } else if (res.statusCode == 401) {
          final refreshed = await AuthService.refreshToken();
          if (refreshed) {
            final newToken = await SessionManager.getToken();
            if (newToken != null) {
              final retryRes = await http.get(
                Uri.parse(url),
                headers: ApiConfig.authHeaders(newToken),
              );
              if (retryRes.statusCode == 200) {
                final retryBody = jsonDecode(retryRes.body);
                if (retryBody is Map<String, dynamic>) {
                  return StudentSnippetData.fromJson(retryBody);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }
}
