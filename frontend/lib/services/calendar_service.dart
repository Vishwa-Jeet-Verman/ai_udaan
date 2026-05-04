import '../config/api_config.dart';
import '../models/calendar_event_model.dart';
import 'api_service.dart';

class CalendarService {
  static Future<List<CalendarEvent>> getEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    final now = DateTime.now();
    final start = from ?? now.subtract(const Duration(days: 30));
    final end = to ?? now.add(const Duration(days: 90));

    final url =
        '${ApiConfig.calendarEvents}'
        '?timestart=${start.millisecondsSinceEpoch ~/ 1000}'
        '&timeend=${end.millisecondsSinceEpoch ~/ 1000}';

    final data = await ApiService.get(url, auth: true);
    return (data['events'] as List? ?? [])
        .map((j) => CalendarEvent.fromJson(j))
        .toList();
  }

  static Future<CalendarEvent> createEvent({
    required String name,
    String description = '',
    required DateTime startAt,
    Duration duration = Duration.zero,
    String eventtype = 'user',
    String? courseid,
  }) async {
    final body = {
      'name': name,
      'description': description,
      'timestart': startAt.millisecondsSinceEpoch ~/ 1000,
      'timeduration': duration.inSeconds,
      'eventtype': eventtype,
      'courseid': ?courseid,
    };
    final data = await ApiService.post(
      ApiConfig.calendarEvents,
      body: body,
      auth: true,
    );
    return CalendarEvent.fromJson(data['event']);
  }

  static Future<void> deleteEvent(String id) async {
    await ApiService.delete(ApiConfig.calendarEventDetail(id), auth: true);
  }

  static Future<void> updateEvent(
    String id, {
    String? name,
    String? description,
    DateTime? startAt,
    Duration? duration,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (startAt != null) body['timestart'] = startAt.millisecondsSinceEpoch ~/ 1000;
    if (duration != null) body['timeduration'] = duration.inSeconds;

    await ApiService.put(
      ApiConfig.calendarEventDetail(id),
      body: body,
      auth: true,
    );
  }
}
