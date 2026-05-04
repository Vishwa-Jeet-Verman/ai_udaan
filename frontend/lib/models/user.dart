import '../config/api_config.dart';

class User {
  final String id;
  final String name;
  final String? username;
  final String email;
  final String role;
  final String? avatarUrl;
  final int? moodleId;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.moodleId,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawAvatarUrl = json['avatar_url'] as String?;
    // Filter out Moodle's default placeholder avatar (not a real user photo)
    final isMoodlePlaceholder = rawAvatarUrl != null &&
        rawAvatarUrl.contains('theme/image.php') &&
        rawAvatarUrl.contains('/u/f');
    final normalizedAvatarUrl = isMoodlePlaceholder
        ? null
        : (rawAvatarUrl != null && rawAvatarUrl.startsWith('/'))
            ? '${ApiConfig.baseUrl.replaceFirst('/api', '')}$rawAvatarUrl'
            : rawAvatarUrl;

    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] as String?,
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      avatarUrl: normalizedAvatarUrl,
      moodleId: (json['moodleId'] ?? json['moodle_id']) as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'])
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'moodleId': moodleId,
    };
  }

  String get displayName {
    final trimmedName = name.trim();
    final normalizedName = trimmedName.replaceFirst(
      RegExp(r'\s+user$', caseSensitive: false),
      '',
    );

    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final trimmedUsername = username?.trim();
    if (trimmedUsername != null && trimmedUsername.isNotEmpty) {
      return trimmedUsername;
    }

    return trimmedName;
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
}
