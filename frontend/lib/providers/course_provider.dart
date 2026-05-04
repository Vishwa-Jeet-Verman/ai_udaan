import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/api_service.dart';

class CourseProvider extends ChangeNotifier {
  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages;

  /// Fetch courses (first page or refresh).
  Future<void> fetchCourses({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _courses = [];
    }

    _setLoading(true);
    _error = null;

    try {
      final result = await CourseService.listCourses(page: _currentPage);
      final fetched = result['courses'] as List<Course>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (refresh || _currentPage == 1) {
        _courses = fetched;
      } else {
        _courses.addAll(fetched);
      }

      _totalPages = pagination['totalPages'] ?? 1;
      _setLoading(false);
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load courses.';
      _setLoading(false);
    }
  }

  /// Create a new course (teacher / admin).
  Future<bool> createCourse({
    required String title,
    String? description,
    double price = 0,
    String? thumbnailUrl,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await CourseService.createCourse(
        title: title,
        description: description,
        price: price,
        thumbnailUrl: thumbnailUrl,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Failed to create course.';
      _setLoading(false);
      return false;
    }
  }

  /// Fetch teacher's own courses.
  Future<List<Course>> fetchMyCourses() async {
    try {
      return await CourseService.listMyCourses();
    } catch (_) {
      return [];
    }
  }

  /// Load next page.
  Future<void> loadMore() async {
    if (!hasMore || _isLoading) return;
    _currentPage++;
    await fetchCourses();
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
