import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static Future<void> checkEmailStatus({
    required String email,
    String purpose = 'register',
  }) async {
    await ApiService.post(
      ApiConfig.checkEmail,
      body: {'email': email, 'purpose': purpose},
    );
  }

  /// Initiate registration — backend sends OTP to [email].
  /// Returns the normalised email on success.
  static Future<String> register({
    required String name,
    required String username,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    final data = await ApiService.post(
      ApiConfig.register,
      body: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    // Backend returns { otpSent: true, email, message }
    return (data['email'] as String?) ?? email;
  }

  /// Verify [otp] for [email] and complete registration.
  /// Saves the JWT and returns {token, user}.
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await ApiService.post(
      ApiConfig.verifyOtp,
      body: {'email': email, 'otp': otp},
    );
    await ApiService.saveToken(data['token']);
    return {'token': data['token'], 'user': User.fromJson(data['user'])};
  }

  /// Login. Returns {token, user}.
  static Future<Map<String, dynamic>> login({
    required String identifier, // Can be email or username
    required String password,
  }) async {
    final data = await ApiService.post(
      ApiConfig.login,
      body: {'identifier': identifier, 'password': password},
    );
    await ApiService.saveToken(data['token']);
    await ApiService.saveSesskey(data['sesskey']); // Save session key if available
    return {'token': data['token'], 'user': User.fromJson(data['user'])};
  }

  /// Change password for the currently logged-in user.
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiService.post(
      ApiConfig.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      auth: true,
    );
  }

  /// Step 1 of forgot-password: send OTP to email.
  static Future<void> forgotPassword({required String email}) async {
    await ApiService.post(
      ApiConfig.forgotPassword,
      body: {'email': email},
    );
  }

  /// Step 2 of forgot-password: verify OTP and set new password.
  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await ApiService.post(
      ApiConfig.resetPassword,
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
  }

  /// Logout — clears stored token and session key.
  static Future<void> logout() async {
    await ApiService.deleteToken();
    await ApiService.deleteSesskey();
  }

  /// Check if user has a stored token (for auto-login).
  static Future<bool> hasToken() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }
}
