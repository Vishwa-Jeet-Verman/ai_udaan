class Course {
  final String id;
  final String title;
  final String? description;
  final double price;
  final String? thumbnailUrl;
  final String createdBy;
  final String? creatorName;
  final String status; // pending, approved, rejected
  final DateTime? createdAt;
  final String? level; // e.g. 'basic', 'advanced', null

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.thumbnailUrl,
    required this.createdBy,
    this.creatorName,
    this.status = 'pending',
    this.createdAt,
    this.level,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    String? creatorName;
    if (json['creator'] != null) {
      creatorName = json['creator']['name'];
    }

    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      thumbnailUrl: json['thumbnail_url'],
      createdBy: json['created_by'] ?? '',
      creatorName: creatorName,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      level: json['level']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'thumbnail_url': thumbnailUrl,
      'status': status,
    };
  }

  bool get isFree => price == 0;

  String get priceDisplay =>
      isFree ? 'Free' : '\u20B9${price.toStringAsFixed(0)}';

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}
