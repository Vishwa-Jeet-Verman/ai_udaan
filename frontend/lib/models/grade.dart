class GradeItem {
  final String id;
  final String itemname;
  final String itemtype;
  final String? itemmodule;
  final double? graderaw;
  final double grademin;
  final double grademax;
  final String gradeformatted;
  final String? percentageformatted;
  final String? feedback;

  const GradeItem({
    required this.id,
    required this.itemname,
    required this.itemtype,
    this.itemmodule,
    this.graderaw,
    required this.grademin,
    required this.grademax,
    required this.gradeformatted,
    this.percentageformatted,
    this.feedback,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) => GradeItem(
        id: json['id'] as String? ?? '',
        itemname: json['itemname'] as String? ?? 'Unnamed',
        itemtype: json['itemtype'] as String? ?? 'mod',
        itemmodule: json['itemmodule'] as String?,
        graderaw: (json['graderaw'] as num?)?.toDouble(),
        grademin: (json['grademin'] as num?)?.toDouble() ?? 0,
        grademax: (json['grademax'] as num?)?.toDouble() ?? 100,
        gradeformatted: json['gradeformatted'] as String? ?? '-',
        percentageformatted: json['percentageformatted'] as String?,
        feedback: json['feedback'] as String?,
      );

  double? get percentage {
    if (graderaw == null || grademax == 0) return null;
    return (graderaw! / grademax) * 100;
  }
}

class CourseGrade {
  final String courseId;
  final String courseTitle;
  final GradeItem? courseTotal;
  final List<GradeItem> items;

  const CourseGrade({
    required this.courseId,
    required this.courseTitle,
    this.courseTotal,
    required this.items,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) => CourseGrade(
        courseId: json['courseId'] as String,
        courseTitle: json['courseTitle'] as String,
        courseTotal: json['courseTotal'] != null
            ? GradeItem.fromJson(json['courseTotal'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
