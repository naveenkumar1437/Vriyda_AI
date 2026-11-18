import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_manager.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class AuthService {
  /// 1. Login Multi-Org
  /// POST /public/login-multi-org
  static Future<ApiResponse<UserSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginMultiOrg),
        headers: ApiConfig.publicHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final dynamic body = jsonDecode(response.body);
      final isSuccess = body is Map && body['success'] == true;
      final msg = _extractMessage(body, response.statusCode);

      if (isSuccess && body['data'] != null) {
        final session = UserSession.fromJson(body['data']);
        if (session.isOwner || session.isPrincipal) {
          await SessionManager.saveSession(session, rememberMe: rememberMe);
        } else {
          await SessionManager.clear();
        }
        return ApiResponse(
          success: true,
          message: msg,
          data: session,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message: msg,
        statusCode: response.statusCode,
      );
    } catch (e, stack) {
      // ignore: avoid_print
      print('[LOGIN_EXCEPTION] $e\n$stack');
      return ApiResponse(
        success: false,
        message: 'Unable to reach server. Please check your internet connection.',
        statusCode: 500,
      );
    }
  }

  /// 2. Refresh Token
  /// POST /auth/refresh
  static Future<bool> refreshToken() async {
    final storedRefresh = await SessionManager.getRefreshToken();
    if (storedRefresh == null || storedRefresh.isEmpty) {
      await SessionManager.clear();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refreshToken),
        headers: ApiConfig.publicHeaders(),
        body: jsonEncode({'refreshToken': storedRefresh}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['token'] != null) {
          final newToken = body['token'].toString();
          final newRefresh = body['refreshToken']?.toString();
          await SessionManager.updateTokens(
            token: newToken,
            refreshToken: newRefresh,
          );
          return true;
        }
      }

      await SessionManager.clear();
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 3. Get My Profile
  /// GET /my-profile
  static Future<ApiResponse<Map<String, dynamic>>> getMyProfile() async {
    return _authenticatedRequest<Map<String, dynamic>>(
      (token) => http.get(
        Uri.parse(ApiConfig.myProfile),
        headers: ApiConfig.authHeaders(token),
      ),
      parser: (json) => (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// 4. Change Password
  /// POST /my-profile/change-password
  static Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _authenticatedRequest<void>(
      (token) => http.post(
        Uri.parse(ApiConfig.changePassword),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
    );
  }

  /// 5. Forgot Password - Step 1: Send Code
  /// POST /auth/forgot-password
  static Future<ApiResponse<void>> sendForgotPasswordOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPassword),
        headers: ApiConfig.publicHeaders(),
        body: jsonEncode({'email': email.trim()}),
      );

      final body = jsonDecode(response.body);
      final msg = _extractMessage(body, response.statusCode);

      return ApiResponse(
        success: response.statusCode == 200 || body['success'] == true,
        message: msg.isNotEmpty ? msg : 'Verification code sent to your email',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Unable to reach the server. Please try again.',
        statusCode: 500,
      );
    }
  }

  /// 6. Forgot Password - Step 2: Verify Code
  /// POST /auth/verify-otp
  static Future<ApiResponse<String>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: ApiConfig.publicHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
        }),
      );

      final body = jsonDecode(response.body);
      final msg = _extractMessage(body, response.statusCode);
      final resetToken = body['resetToken']?.toString();

      if ((response.statusCode == 200 || body['success'] == true) && resetToken != null) {
        return ApiResponse(
          success: true,
          message: msg.isNotEmpty ? msg : 'OTP verified successfully',
          data: resetToken,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message: msg,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Something went wrong, please try again.',
        statusCode: 500,
      );
    }
  }

  /// 7. Forgot Password - Step 3: Set New Password
  /// POST /auth/reset-password
  static Future<ApiResponse<void>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPassword),
        headers: ApiConfig.publicHeaders(),
        body: jsonEncode({
          'email': email.trim(),
          'resetToken': resetToken,
          'newPassword': newPassword,
        }),
      );

      final body = jsonDecode(response.body);
      final msg = _extractMessage(body, response.statusCode);

      return ApiResponse(
        success: response.statusCode == 200 || body['success'] == true,
        message: msg,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse(
        success: false,
        message: 'Something went wrong, please try again.',
        statusCode: 500,
      );
    }
  }

  /// 8. School Logo
  /// GET /organizations/me/logo
  static Future<String?> getOrgLogo() async {
    final res = await _authenticatedRequest<String?>(
      (token) => http.get(
        Uri.parse(ApiConfig.orgLogo),
        headers: ApiConfig.authHeaders(token),
      ),
      parser: (json) {
        final path = json['data']?['url']?.toString();
        return ApiConfig.resolveImageUrl(path);
      },
    );
    return res.data;
  }

  // --- Helper for Authenticated Requests with 401 Auto-Refresh ---
  static Future<ApiResponse<T>> _authenticatedRequest<T>(
    Future<http.Response> Function(String token) call, {
    T Function(dynamic json)? parser,
  }) async {
    String? token = await SessionManager.getToken();
    if (token == null) {
      return ApiResponse(
        success: false,
        message: 'Not logged in. Please sign in.',
        statusCode: 401,
      );
    }

    try {
      http.Response response = await call(token);

      // Handle 401 Token Expiry with Refresh Token
      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          token = await SessionManager.getToken();
          if (token != null) {
            response = await call(token);
          }
        } else {
          return ApiResponse(
            success: false,
            message: 'Session expired. Please log in again.',
            statusCode: 401,
          );
        }
      }

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = null;
      }

      final isSuccess = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (body is Map ? (body['success'] ?? true) : true);

      final msg = _extractMessage(body, response.statusCode);

      T? parsedData;
      if (isSuccess && parser != null && body != null) {
        parsedData = parser(body);
      }

      return ApiResponse(
        success: isSuccess,
        message: msg,
        data: parsedData,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error. Please try again.',
        statusCode: 500,
      );
    }
  }

  static String _extractMessage(dynamic body, int statusCode) {
    if (body is Map) {
      if (body['message'] != null && body['message'].toString().isNotEmpty) {
        return body['message'].toString();
      }
      if (body['error'] != null && body['error'].toString().isNotEmpty) {
        return body['error'].toString();
      }
    }
    switch (statusCode) {
      case 400:
        return 'Invalid request details.';
      case 401:
        return 'Invalid email or password.';
      case 403:
        return 'Access denied for this account.';
      case 429:
        return 'Too many attempts. Please wait 15 minutes before trying again.';
      case 500:
        return 'Something went wrong, try again.';
      default:
        return 'An unexpected response occurred.';
    }
  }
}
