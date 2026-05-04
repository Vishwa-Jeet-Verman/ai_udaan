import 'package:flutter/material.dart';
import '../models/calendar_event_model.dart';
import '../services/calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _error;

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CalendarEvent> eventsForDay(DateTime day) {
    return _events.where((e) {
      final d = e.startAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _events = await CalendarService.getEvents();
    } catch (e) {
      _error = 'Failed to load events.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CalendarEvent?> createEvent({
    required String name,
    String description = '',
    required DateTime startAt,
    Duration duration = Duration.zero,
    String eventtype = 'user',
    String? courseid,
  }) async {
    try {
      final event = await CalendarService.createEvent(
        name: name,
        description: description,
        startAt: startAt,
        duration: duration,
        eventtype: eventtype,
        courseid: courseid,
      );
      _events = [..._events, event]
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      notifyListeners();
      return event;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    await CalendarService.deleteEvent(id);
    _events = _events.where((e) => e.id != id).toList();
    notifyListeners();
  }
}
