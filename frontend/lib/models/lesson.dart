class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String type; // 'video' or 'pdf'
  final String fileUrl;
  final int sortOrder;
  final String? signedUrl;
  final String? courseTitle;
  final String? sectionName;
  final int? sectionId;
  final String? moduleName;
  final String? description;
  final String contentStatus; // pending, approved, rejected
  final DateTime? createdAt;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.fileUrl,
    required this.sortOrder,
    this.signedUrl,
    this.courseTitle,
    this.sectionName,
    this.sectionId,
    this.moduleName,
    this.description,
    this.contentStatus = 'pending',
    this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    String? courseTitle;
    if (json['course'] != null) {
      courseTitle = json['course']['title'];
    }

    return Lesson(
      id: json['id'] ?? '',
      courseId: json['course_id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'video',
      fileUrl: json['file_url'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      signedUrl: json['signed_url'],
      courseTitle: courseTitle,
      sectionName: json['section_name'],
      sectionId: json['section_id'],
      moduleName: json['module_name'],
      description: json['description'],
      contentStatus: json['content_status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  bool get isVideo => type == 'video';
  bool get isPdf => type == 'pdf';
  bool get isApproved => contentStatus == 'approved';
  bool get isPending => contentStatus == 'pending';
}
