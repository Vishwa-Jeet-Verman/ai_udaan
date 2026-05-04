import '../config/api_config.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';
import 'api_service.dart';

class AdminService {
  // ─── Courses ───

  /// List all courses (any status) — admin only.
  static Future<Map<String, dynamic>> listAllCourses({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    String url = '${ApiConfig.adminAllCourses}?page=$page&limit=$limit';
    if (status != null) url += '&status=$status';

    final data = await ApiService.get(url, auth: true);
    final courses = (data['courses'] as List)
        .map((json) => Course.fromJson(json))
        .toList();
    return {
      'courses': courses,
      'pagination': data['pagination'],
    };
  }

  /// Approve or reject a course.
  static Future<Course> updateCourseStatus(
      String courseId, String status) async {
    final data = await ApiService.patch(
      ApiConfig.adminCourseStatus(courseId),
      body: {'status': status},
      auth: true,
    );
    return Course.fromJson(data['course']);
  }

  // ─── Lessons ───

  /// List all lessons (any content_status) — admin only.
  static Future<Map<String, dynamic>> listAllLessons({
    int page = 1,
    int limit = 50,
    String? contentStatus,
  }) async {
    String url = '${ApiConfig.adminAllLessons}?page=$page&limit=$limit';
    if (contentStatus != null) url += '&content_status=$contentStatus';

    final data = await ApiService.get(url, auth: true);
    final lessons = (data['lessons'] as List)
        .map((json) => Lesson.fromJson(json))
        .toList();
    return {
      'lessons': lessons,
      'pagination': data['pagination'],
    };
  }

  /// Approve or reject a lesson.
  static Future<Lesson> updateLessonStatus(
      String lessonId, String contentStatus) async {
    final data = await ApiService.patch(
      ApiConfig.adminLessonStatus(lessonId),
      body: {'content_status': contentStatus},
      auth: true,
    );
    return Lesson.fromJson(data['lesson']);
  }

  // ─── Transactions ───

  /// List all transactions — admin only.
  static Future<Map<String, dynamic>> listAllTransactions({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    String url = '${ApiConfig.adminTransactions}?page=$page&limit=$limit';
    if (status != null) url += '&status=$status';

    final data = await ApiService.get(url, auth: true);
    final transactions = (data['transactions'] as List)
        .map((json) => Enrollment.fromJson(json))
        .toList();
    return {
      'transactions': transactions,
      'pagination': data['pagination'],
    };
  }

  /// Verify or reject a transaction.
  static Future<Enrollment> updateTransactionStatus(
      String transactionId, String status) async {
    final data = await ApiService.patch(
      ApiConfig.adminTransactionStatus(transactionId),
      body: {'transaction_status': status},
      auth: true,
    );
    return Enrollment.fromJson(data['enrollment']);
  }
}
