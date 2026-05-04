class DownloadItem {
  final String id;
  final String courseId;
  final String courseTitle;
  final String? sectionName;
  final String moduleName;
  final String filename;
  final String fileurl;
  final String mimetype;
  final int filesize;
  final String filesizeFormatted;
  final DateTime? timemodified;

  const DownloadItem({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    this.sectionName,
    required this.moduleName,
    required this.filename,
    required this.fileurl,
    required this.mimetype,
    required this.filesize,
    required this.filesizeFormatted,
    this.timemodified,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      courseTitle: json['courseTitle'] as String,
      sectionName: json['sectionName'] as String?,
      moduleName: json['moduleName'] as String? ?? json['filename'] as String,
      filename: json['filename'] as String,
      fileurl: json['fileurl'] as String,
      mimetype: json['mimetype'] as String? ?? 'application/octet-stream',
      filesize: (json['filesize'] as num?)?.toInt() ?? 0,
      filesizeFormatted: json['filesizeFormatted'] as String? ?? '',
      timemodified: json['timemodified'] != null
          ? DateTime.tryParse(json['timemodified'] as String)
          : null,
    );
  }
}
