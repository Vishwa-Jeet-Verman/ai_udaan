import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';
import '../services/admin_service.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  // ─── Courses ───
  List<Course> _courses = [];
  bool _coursesLoading = false;
  String? _coursesError;

  List<Course> get courses => _courses;
  bool get coursesLoading => _coursesLoading;
  String? get coursesError => _coursesError;

  Future<void> fetchAllCourses({String? status}) async {
    _coursesLoading = true;
    _coursesError = null;
    notifyListeners();

    try {
      final result = await AdminService.listAllCourses(status: status);
      _courses = result['courses'] as List<Course>;
      _coursesLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _coursesError = e.message;
      _coursesLoading = false;
      notifyListeners();
    } catch (e) {
      _coursesError = 'Failed to load courses.';
      _coursesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCourseStatus(String courseId, String status) async {
    try {
      final updated = await AdminService.updateCourseStatus(courseId, status);
      final index = _courses.indexWhere((c) => c.id == courseId);
      if (index >= 0) {
        _courses[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _coursesError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _coursesError = 'Failed to update course status.';
      notifyListeners();
      return false;
    }
  }

  // ─── Lessons ───
  List<Lesson> _lessons = [];
  bool _lessonsLoading = false;
  String? _lessonsError;

  List<Lesson> get lessons => _lessons;
  bool get lessonsLoading => _lessonsLoading;
  String? get lessonsError => _lessonsError;

  Future<void> fetchAllLessons({String? contentStatus}) async {
    _lessonsLoading = true;
    _lessonsError = null;
    notifyListeners();

    try {
      final result =
          await AdminService.listAllLessons(contentStatus: contentStatus);
      _lessons = result['lessons'] as List<Lesson>;
      _lessonsLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _lessonsError = e.message;
      _lessonsLoading = false;
      notifyListeners();
    } catch (e) {
      _lessonsError = 'Failed to load lessons.';
      _lessonsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateLessonStatus(
      String lessonId, String contentStatus) async {
    try {
      final updated =
          await AdminService.updateLessonStatus(lessonId, contentStatus);
      final index = _lessons.indexWhere((l) => l.id == lessonId);
      if (index >= 0) {
        _lessons[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _lessonsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _lessonsError = 'Failed to update lesson status.';
      notifyListeners();
      return false;
    }
  }

  // ─── Transactions ───
  List<Enrollment> _transactions = [];
  bool _transactionsLoading = false;
  String? _transactionsError;

  List<Enrollment> get transactions => _transactions;
  bool get transactionsLoading => _transactionsLoading;
  String? get transactionsError => _transactionsError;

  Future<void> fetchAllTransactions({String? status}) async {
    _transactionsLoading = true;
    _transactionsError = null;
    notifyListeners();

    try {
      final result =
          await AdminService.listAllTransactions(status: status);
      _transactions = result['transactions'] as List<Enrollment>;
      _transactionsLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _transactionsError = e.message;
      _transactionsLoading = false;
      notifyListeners();
    } catch (e) {
      _transactionsError = 'Failed to load transactions.';
      _transactionsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTransactionStatus(
      String transactionId, String status) async {
    try {
      final updated = await AdminService.updateTransactionStatus(
          transactionId, status);
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index >= 0) {
        _transactions[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _transactionsError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _transactionsError = 'Failed to update transaction status.';
      notifyListeners();
      return false;
    }
  }
}
