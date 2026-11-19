import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// User Session and Auth Response Model
class UserSession {
  final String id;
  final String token;
  final String? refreshToken;
  final String email;
  final String name;
  final String role;
  final List<String> roles;
  final String? branchId;
  final String? branchName;
  final String? organizationId;
  final String? organizationName;
  final bool mustChangePassword;

  UserSession({
    required this.id,
    required this.token,
    this.refreshToken,
    required this.email,
    required this.name,
    required this.role,
    this.roles = const [],
    this.branchId,
    this.branchName,
    this.organizationId,
    this.organizationName,
    required this.mustChangePassword,
  });

  bool get isOwner {
    final r = role.trim().toLowerCase();
    if (r == 'owner' || r == 'chairman') return true;
    for (final item in roles) {
      final sub = item.trim().toLowerCase();
      if (sub == 'owner' || sub == 'chairman') return true;
    }
    return false;
  }

  bool get isPrincipal {
    final r = role.trim().toLowerCase();
    if (r == 'principal') return true;
    for (final item in roles) {
      final sub = item.trim().toLowerCase();
      if (sub == 'principal') return true;
    }
    return false;
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      roles: (json['roles'] is List)
          ? (json['roles'] as List).map((e) => e.toString()).toList()
          : (json['role'] != null ? [json['role'].toString()] : const []),
      branchId: json['branch_id']?.toString() ?? json['branchId']?.toString(),
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString(),
      organizationId: json['organizationId']?.toString(),
      organizationName: json['organizationName']?.toString(),
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'refreshToken': refreshToken,
        'email': email,
        'name': name,
        'role': role,
        'roles': roles,
        'branch_id': branchId,
        'branch_name': branchName,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'mustChangePassword': mustChangePassword,
      };
}

/// Token & Session Storage Manager
class SessionManager {
  static const String _keyToken = 'vriyda_token';
  static const String _keyRefreshToken = 'vriyda_refresh_token';
  static const String _keyUserSession = 'vriyda_user_session';
  static const String _keyRememberMe = 'vriyda_remember_me';
  static const String _keyProfileDetails = 'vriyda_profile_details';

  static Future<void> saveProfileDetails(Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileDetails, jsonEncode(details));
  }

  static Future<Map<String, dynamic>?> getProfileDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfileDetails);
    if (raw != null) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static Future<void> saveSession(UserSession session, {bool rememberMe = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, session.token);
    if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
      await prefs.setString(_keyRefreshToken, session.refreshToken!);
    } else {
      await prefs.remove(_keyRefreshToken);
    }
    await prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_keyUserSession, jsonEncode(session.toJson()));
    } else {
      await prefs.remove(_keyUserSession);
    }
  }

  static Future<bool> isRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<UserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserSession);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return UserSession.fromJson(map);
      } catch (_) {}
    }
    return null;
  }

  static Future<void> updateTokens({required String token, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }
    final session = await getSession();
    if (session != null) {
      final updated = UserSession(
        id: session.id,
        token: token,
        refreshToken: refreshToken ?? session.refreshToken,
        email: session.email,
        name: session.name,
        role: session.role,
        roles: session.roles,
        branchId: session.branchId,
        branchName: session.branchName,
        organizationId: session.organizationId,
        organizationName: session.organizationName,
        mustChangePassword: session.mustChangePassword,
      );
      final remembered = await isRemembered();
      await saveSession(updated, rememberMe: remembered);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserSession);
    await prefs.remove(_keyRememberMe);
  }
}
