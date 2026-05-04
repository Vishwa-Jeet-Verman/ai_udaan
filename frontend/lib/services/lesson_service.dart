import '../config/api_config.dart';
import '../models/lesson.dart';
import 'api_service.dart';

class LessonService {
  /// List lessons for a course (must be enrolled or admin).
  static Future<List<Lesson>> listLessons(String courseId) async {
    final data = await ApiService.get(
      ApiConfig.courseLessons(courseId),
      auth: true,
    );
    return (data['lessons'] as List)
        .map((json) => Lesson.fromJson(json))
        .toList();
  }

  /// Get single lesson with signed URL (must be enrolled or admin).
  static Future<Lesson> getLesson(String id) async {
    final data = await ApiService.get(
      ApiConfig.lessonDetail(id),
      auth: true,
    );
    return Lesson.fromJson(data['lesson']);
  }
}
