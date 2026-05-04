import 'package:flutter/material.dart';
import '../models/course.dart';


class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool showEnrolledBadge;
  final Color? backgroundColor;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showEnrolledBadge = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode
        ? const Color(0xFF1E3A34)  // Dark green
        : const Color(0xFFEAF5F2); // Light green
    final textPrimaryColor =
        isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF1A1A1A);
    final textSecondaryColor =
        isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    final tagBgColor = isDarkMode
        ? const Color(0xFF254D45)  // Slightly lighter dark green
        : const Color(0xFFDDEEE8); // Light green
    final tagTextColor = isDarkMode
        ? const Color(0xFF34D399)  // Bright green
        : const Color(0xFF1F7A63); // Forest green
    final placeholderBgColor =
        isDarkMode ? const Color(0xFF254D45) : const Color(0xFFDDEEE8);
    final iconColor = isDarkMode
        ? const Color(0xFF34D399)  // Bright green
        : const Color(0xFF1F7A63); // Forest green
    final cardBorderColor =
        isDarkMode ? const Color(0xFF2F4F4F) : const Color(0xFFD1E7E0);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                if (course.thumbnailUrl != null &&
                    course.thumbnailUrl!.isNotEmpty)
                  Image.network(
                    course.thumbnailUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context2, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context2, error, stackTrace) =>
                        _placeholderThumbnail(context, placeholderBgColor, iconColor),
                  )
                else
                  _placeholderThumbnail(context, placeholderBgColor, iconColor),

                // Price badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: course.isFree ? tagBgColor : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF2A2A2A)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      course.priceDisplay,
                      style: TextStyle(
                        color: course.isFree
                            ? tagTextColor
                            : (isDarkMode ? Colors.white : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // Enrolled badge
                if (showEnrolledBadge)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: tagTextColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Enrolled',
                            style: TextStyle(
                              color: tagTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.description != null &&
                      course.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (course.creatorName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 14, color: textSecondaryColor),
                        const SizedBox(width: 4),
                        Text(
                          course.creatorName!,
                          style: TextStyle(
                              fontSize: 12, color: textSecondaryColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumbnail(
      BuildContext context, Color bgColor, Color iconColor) {
    return Container(
      height: 160,
      width: double.infinity,
      color: bgColor,
      child: Icon(
        Icons.school,
        size: 48,
        color: iconColor,
      ),
    );
  }
}
