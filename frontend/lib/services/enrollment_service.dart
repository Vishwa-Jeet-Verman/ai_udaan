import '../config/api_config.dart';
import '../models/enrollment.dart';
import 'api_service.dart';

class EnrollmentService {
  /// Enroll the current user in a course.
  static Future<Enrollment> enroll(String courseId) async {
    final data = await ApiService.post(
      ApiConfig.enrollInCourse(courseId),
      auth: true,
    );
    return Enrollment.fromJson(data['enrollment']);
  }

  /// Get the current user's enrollments.
  static Future<List<Enrollment>> getMyEnrollments() async {
    final data = await ApiService.get(ApiConfig.enrollments, auth: true);
    return (data['enrollments'] as List)
        .map((json) => Enrollment.fromJson(json))
        .toList();
  }
}
