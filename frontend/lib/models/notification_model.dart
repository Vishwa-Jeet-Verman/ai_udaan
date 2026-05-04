class AppNotification {
  final String id;
  final String type; // enrollment, assignment, grade, new_course, info
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String source;
  final NotificationData? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    required this.source,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      read: json['read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] ?? 'moodle',
      data: json['data'] != null
          ? NotificationData.fromJson(json['data'])
          : null,
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        read: read ?? this.read,
        createdAt: createdAt,
        source: source,
        data: data,
      );
}

class NotificationData {
  final String? courseId;
  final String? cmId;
  final String? moodleNotifId;
  final String? contexturl;
  final String? enrolledAt;

  NotificationData({this.courseId, this.cmId, this.moodleNotifId, this.contexturl, this.enrolledAt});

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      courseId: json['courseId']?.toString(),
      cmId: json['cmId']?.toString(),
      moodleNotifId: json['moodleNotifId']?.toString(),
      contexturl: json['contexturl']?.toString(),
      enrolledAt: json['enrolledAt']?.toString(),
    );
  }
}
