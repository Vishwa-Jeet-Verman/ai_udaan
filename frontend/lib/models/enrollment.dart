import 'course.dart';

class Enrollment {
  final String id;
  final String userId;
  final String courseId;
  final String transactionStatus; // pending, verified, rejected
  final DateTime? enrolledAt;
  final Course? course;
  final String? userName;
  final String? userEmail;

  Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    this.transactionStatus = 'pending',
    this.enrolledAt,
    this.course,
    this.userName,
    this.userEmail,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    String? userName;
    String? userEmail;
    if (json['user'] != null) {
      userName = json['user']['name'];
      userEmail = json['user']['email'];
    }

    return Enrollment(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      courseId: json['course_id'] ?? '',
      transactionStatus: json['transaction_status'] ?? 'pending',
      enrolledAt: json['enrolled_at'] != null
          ? DateTime.tryParse(json['enrolled_at'])
          : null,
      course:
          json['course'] != null ? Course.fromJson(json['course']) : null,
      userName: userName,
      userEmail: userEmail,
    );
  }

  bool get isVerified => transactionStatus == 'verified' || transactionStatus == 'approved';
  bool get isPending => transactionStatus == 'pending';
  bool get isRejected => transactionStatus == 'rejected';
}
