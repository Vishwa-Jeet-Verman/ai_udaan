import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  /// Get current user profile.
  static Future<User> getProfile() async {
    final data = await ApiService.get(ApiConfig.profile, auth: true);
    return User.fromJson(data['user']);
  }

  /// Update profile (name, avatar_url).
  static Future<User> updateProfile({String? name, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    await ApiService.put(
      ApiConfig.profile,
      body: body,
      auth: true,
    );
    // Re-fetch the profile so the returned User reflects the Moodle update.
    return getProfile();
  }

  /// Upload avatar image file.
  static Future<User> uploadAvatar({required String imagePath, required List<int> imageBytes}) async {
    final data = await ApiService.postMultipart(
      ApiConfig.userAvatar,
      fileField: 'avatar',
      filePath: imagePath,
      fileBytes: imageBytes,
      auth: true,
    );
    // Backend returns a new JWT with the updated avatar_url — save it
    if (data['token'] != null) {
      await ApiService.saveToken(data['token'] as String);
    }
    return User.fromJson(data['user']);
  }

  /// List all users (admin only).
  static Future<Map<String, dynamic>> listUsers({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await ApiService.get(
      '${ApiConfig.users}?page=$page&limit=$limit',
      auth: true,
    );
    final users = (data['users'] as List)
        .map((json) => User.fromJson(json))
        .toList();
    return {'users': users, 'pagination': data['pagination']};
  }
}
