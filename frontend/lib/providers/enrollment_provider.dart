import 'package:flutter/material.dart';
import '../models/enrollment.dart';
import '../services/enrollment_service.dart';
import '../services/api_service.dart';

class EnrollmentProvider extends ChangeNotifier {
  List<Enrollment> _enrollments = [];
  bool _isLoading = false;
  String? _error;

  List<Enrollment> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch the current user's enrollments.
  Future<void> fetchEnrollments() async {
    _setLoading(true);
    _error = null;
    try {
      _enrollments = await EnrollmentService.getMyEnrollments();
      _setLoading(false);
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load enrollments.';
      _setLoading(false);
    }
  }

  /// Enroll in a course.
  Future<bool> enroll(String courseId) async {
    _setLoading(true);
    _error = null;
    try {
      debugPrint('[Enrollment] 📝 Attempting to enroll in course: $courseId');
      await EnrollmentService.enroll(courseId);
      debugPrint('[Enrollment] ✅ Enrollment API call successful');
      // Wait briefly for Moodle to propagate the enrollment before re-fetching
      await Future.delayed(const Duration(seconds: 2));
      await fetchEnrollments();
      // If the newly enrolled course still isn't showing, retry once more
      final isNowEnrolled = isEnrolledIn(courseId);
      if (!isNowEnrolled) {
        debugPrint('[Enrollment] ⚠️ Course not found in first fetch, retrying...');
        await Future.delayed(const Duration(seconds: 2));
        await fetchEnrollments();
      }
      debugPrint('[Enrollment] ✅ Enrollment complete for course: $courseId');
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      debugPrint('[Enrollment] ❌ API Error: ${e.message}');
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Failed to enroll.';
      _setLoading(false);
      return false;
    }
  }

  /// Check if user is enrolled in a specific course.
  bool isEnrolledIn(String courseId) {
    return _enrollments.any((e) => e.courseId == courseId);
  }

  void clearEnrollments() {
    _enrollments = [];
    notifyListeners();
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
