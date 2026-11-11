/// Centralized API configuration and endpoints for Vriyda Mobile
class ApiConfig {
  static const String baseUrl = 'https://devportal.innovorex.co.in/api';
  static const String serverHost = 'https://devportal.innovorex.co.in';

  // Part A - Auth & Profile
  static const String loginMultiOrg = '$baseUrl/public/login-multi-org';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String myProfile = '$baseUrl/my-profile';
  static const String changePassword = '$baseUrl/my-profile/change-password';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String orgLogo = '$baseUrl/organizations/me/logo';

  // Part B - Chairman / Owner Screens
  static const String ownerDashboard = '$baseUrl/owner-dashboard';
  static const String ownerAttendance = '$baseUrl/owner-dashboard/attendance';
  static const String ownerApprovals = '$baseUrl/owner-dashboard/approvals';
  static const String ownerStudents = '$baseUrl/owner-dashboard/students';
  static const String ownerStudentSnippet = '$baseUrl/owner-dashboard/student-snippet';
  static const String ownerStudentAiSnippet = '$baseUrl/owner-dashboard/student-snippet/ai';

  // Headers
  static Map<String, String> publicHeaders() => {
        'Content-Type': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$serverHost$path';
  }
}
