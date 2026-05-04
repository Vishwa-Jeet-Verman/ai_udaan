import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _pendingEmail;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isTeacher => _user?.isTeacher ?? false;
  bool get isStudent => _user?.isStudent ?? true;
  String? get error => _error;

  /// The email address waiting for OTP verification (set after register() succeeds).
  String? get pendingEmail => _pendingEmail;

  /// Try auto-login with stored token.
  Future<bool> tryAutoLogin() async {
    final hasToken = await AuthService.hasToken();
    if (!hasToken) return false;

    try {
      _user = await UserService.getProfile();
      final token = await ApiService.getToken();
      if (token != null) SocketService.connect(token);
      notifyListeners();
      return true;
    } catch (e) {
      await AuthService.logout();
      return false;
    }
  }

  /// Step 1 — Initiate registration. Sends OTP to [email].
  /// Returns true when OTP was dispatched; [pendingEmail] is set.
  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
    String role = 'student',
  }) async {
    _setLoading(true);
    _error = null;
    _pendingEmail = null;
    try {
      final confirmedEmail = await AuthService.register(
        name: name,
        username: username,
        email: email,
        password: password,
        role: role,
      );
      _pendingEmail = confirmedEmail;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Step 2 — Verify OTP and complete registration. Returns true on success.
  Future<bool> verifyOtp({required String email, required String otp}) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await AuthService.verifyOtp(email: email, otp: otp);
      _user = result['user'] as User;
      _pendingEmail = null;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Log in.
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await AuthService.login(
        identifier: identifier,
        password: password,
      );

      // Use login payload first, then refresh from profile endpoint.
      // This keeps UI aligned with Moodle-synced user data.
      _user = result['user'] as User;
      try {
        _user = await UserService.getProfile();
      } catch (_) {}

      // ✅ Connect socket ONLY after successful login
      final token = await ApiService.getToken();
      if (token != null) {
        debugPrint('[AuthProvider] 📡 Connecting Socket.IO after login...');
        try {
          await SocketService.connect(token);
          debugPrint('[AuthProvider] ✅ Socket.IO connected');
        } catch (e) {
          debugPrint('[AuthProvider] ⚠️ Socket.IO connection failed: $e');
          // Don't fail login if socket fails - app can still work without real-time
        }
      }

      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Log out.
  Future<void> logout() async {
    // ✅ Disconnect socket BEFORE clearing user data
    debugPrint('[AuthProvider] 🔌 Disconnecting Socket.IO...');
    await SocketService.disconnect();
    
    // Clear local auth data
    await AuthService.logout();
    
    _user = null;
    notifyListeners();
    
    debugPrint('[AuthProvider] ✅ Logged out and cleaned up');
  }

  /// Refresh current user profile from backend.
  Future<void> refreshProfile() async {
    try {
      _user = await UserService.getProfile();
      notifyListeners();
    } catch (_) {
      // Keep current user state on refresh failures.
    }
  }

  /// Update profile.
  Future<bool> updateProfile({String? name, String? avatarUrl}) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await UserService.updateProfile(name: name, avatarUrl: avatarUrl);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Upload avatar image and refresh local user data.
  Future<bool> uploadAvatar({required String imagePath, required List<int> imageBytes}) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await UserService.uploadAvatar(imagePath: imagePath, imageBytes: imageBytes);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Change current user's password.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
