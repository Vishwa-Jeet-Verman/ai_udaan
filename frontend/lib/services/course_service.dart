import '../config/api_config.dart';
import '../models/course.dart';
import 'api_service.dart';

class CourseService {
  /// List all courses (public, paginated).
  static Future<Map<String, dynamic>> listCourses({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await ApiService.get(
      '${ApiConfig.courses}?page=$page&limit=$limit',
    );
    final courses = (data['courses'] as List)
        .map((json) => Course.fromJson(json))
        .toList();
    return {
      'courses': courses,
      'pagination': data['pagination'],
    };
  }

  /// Get single course detail (uses optional auth for enrollment status).
  static Future<Map<String, dynamic>> getCourse(String id) async {
    // Use auth: true so if user is logged in, enrollment status is returned
    final data = await ApiService.get(
      ApiConfig.courseDetail(id),
      auth: true,
    );
    return {
      'course': Course.fromJson(data['course']),
      'isEnrolled': data['isEnrolled'] ?? false,
      'lessonCount': data['lessonCount'] ?? 0,
    };
  }

  /// List teacher's own courses.
  static Future<List<Course>> listMyCourses() async {
    final data = await ApiService.get(ApiConfig.myCourses, auth: true);
    return (data['courses'] as List)
        .map((json) => Course.fromJson(json))
        .toList();
  }

  /// Create a new course (admin).
  static Future<Course> createCourse({
    required String title,
    String? description,
    double price = 0,
    String? thumbnailUrl,
  }) async {
    final data = await ApiService.post(
      ApiConfig.courses,
      body: {
        'title': title,
        'description': description,
        'price': price,
        'thumbnail_url': thumbnailUrl,
      },
      auth: true,
    );
    return Course.fromJson(data['course']);
  }

  /// Update a course (admin).
  static Future<Course> updateCourse(
    String id, {
    String? title,
    String? description,
    double? price,
    String? thumbnailUrl,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (thumbnailUrl != null) body['thumbnail_url'] = thumbnailUrl;

    final data = await ApiService.put(
      ApiConfig.courseDetail(id),
      body: body,
      auth: true,
    );
    return Course.fromJson(data['course']);
  }

  /// Delete a course (admin).
  static Future<void> deleteCourse(String id) async {
    await ApiService.delete(ApiConfig.courseDetail(id), auth: true);
  }
}
