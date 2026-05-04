import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required .env key: $key');
    }
    return value;
  }

  static bool get _isProd =>
      (dotenv.env['APP_ENV'] ?? 'dev').toLowerCase() == 'prod';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    if (_isProd) return _require('API_BASE_URL_PROD');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _require('API_BASE_URL_ANDROID');
    }
    return _require('API_BASE_URL_LOCAL');
  }

  static String get socketUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override.replaceFirst('/api', '');

    if (_isProd) return _require('SOCKET_URL_PROD');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _require('SOCKET_URL_ANDROID');
    }
    return _require('SOCKET_URL_LOCAL');
  }

  static String get moodleUrl => _require('MOODLE_URL');

  // Auth endpoints
  static String get checkEmail => '$baseUrl/auth/check-email';
  static String get register => '$baseUrl/auth/register';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get login => '$baseUrl/auth/login';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get changePassword => '$baseUrl/auth/change-password';

  // User endpoints
  static String get profile => '$baseUrl/users/me';
  static String get userAvatar => '$baseUrl/users/avatar';
  static String get users => '$baseUrl/users';

  // Course endpoints
  static String get courses => '$baseUrl/courses';
  static String courseDetail(String id) => '$baseUrl/courses/$id';
  static String get myCourses => '$baseUrl/courses/my';

  // Admin course endpoints
  static String get adminAllCourses => '$baseUrl/courses/admin/all';
  static String adminCourseStatus(String id) => '$baseUrl/courses/$id/status';

  // Lesson endpoints
  static String courseLessons(String courseId) =>
      '$baseUrl/courses/$courseId/lessons';
  static String lessonDetail(String id) => '$baseUrl/lessons/$id';
  static String adminLessonStatus(String id) => '$baseUrl/lessons/$id/status';
  static String get adminAllLessons => '$baseUrl/admin/lessons';

  // Enrollment endpoints
  static String enrollInCourse(String courseId) =>
      '$baseUrl/courses/$courseId/enroll';
  static String get enrollments => '$baseUrl/enrollments';

  // Admin transaction endpoints
  static String get adminTransactions => '$baseUrl/admin/transactions';
  static String adminTransactionStatus(String id) =>
      '$baseUrl/admin/transactions/$id/status';

  // Health
  static String get health => '$baseUrl/health';

  // Message endpoints
  static String get messageGroups => '$baseUrl/messages/groups';
  static String messageGroupMessages(String groupId) =>
      '$baseUrl/messages/groups/$groupId/messages';
  static String messageGroupJoin(String groupId) =>
      '$baseUrl/messages/groups/$groupId/join';
  static String messageGroupLeave(String groupId) =>
      '$baseUrl/messages/groups/$groupId/leave';
  static String get messagePrivateConversations =>
      '$baseUrl/messages/private/conversations';
  static String messagePrivate(String partnerId) =>
      '$baseUrl/messages/private/$partnerId';
  static String messagePrivatePoll(String partnerId) =>
      '$baseUrl/messages/private/$partnerId/poll';
  static String messagePrivateMarkRead(String partnerId) =>
      '$baseUrl/messages/private/$partnerId/read-all';
  static String get messageSendPrivate => '$baseUrl/messages/private';
  static String get messageStarred => '$baseUrl/messages/starred';
  static String messageToggleStar(String messageId) =>
      '$baseUrl/messages/starred/$messageId/toggle';
  static String messageMarkRead(String messageId) =>
      '$baseUrl/messages/read/$messageId';

  // Notification endpoints
  static String get notifications => '$baseUrl/notifications';
  static String notificationMarkRead(String id) =>
      '$baseUrl/notifications/$id/read';
  static String get notificationsMarkAllRead =>
      '$baseUrl/notifications/read-all';

  // Calendar endpoints
  static String get calendarEvents => '$baseUrl/calendar/events';
  static String calendarEventDetail(String id) =>
      '$baseUrl/calendar/events/$id';

  // Downloads endpoint
  static String get downloads => '$baseUrl/downloads';
}
