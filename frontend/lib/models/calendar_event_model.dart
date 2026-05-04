class CalendarEvent {
  final String id;
  final String name;
  final String description;
  final int timestart;      // Unix timestamp
  final int timeduration;   // seconds
  final String eventtype;   // 'user', 'course', 'site'
  final String? courseid;
  final DateTime startAt;
  final DateTime? endAt;

  CalendarEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.timestart,
    required this.timeduration,
    required this.eventtype,
    this.courseid,
    required this.startAt,
    this.endAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      timestart: json['timestart'] ?? 0,
      timeduration: json['timeduration'] ?? 0,
      eventtype: json['eventtype'] ?? 'user',
      courseid: json['courseid']?.toString(),
      startAt: json['startAt'] != null
          ? DateTime.tryParse(json['startAt']) ?? DateTime.now()
          : DateTime.now(),
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'timestart': timestart,
        'timeduration': timeduration,
        'eventtype': eventtype,
        if (courseid != null) 'courseid': courseid,
      };
}
