import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/user_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 760,
      desktop: 860,
    );

    return Scaffold(
      appBar: AppBar(
        title: Consumer<NotificationProvider>(
          builder: (context2, np, child2) {
            final count = np.unreadCount;
            return Row(
              children: [
                const Text('Notifications'),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context3, np, child3) {
              if (np.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: np.markAllRead,
                child: Text(AppLocalizations.of(context)!.markAllRead),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAvatar(radius: 16, fontSize: 12),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Consumer<NotificationProvider>(
            builder: (context, np, _) {
              if (np.isLoading && np.notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (np.error != null && np.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(np.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: np.fetchNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (np.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: AppResponsive.adaptiveSize(context, mobile: 76, tablet: 92, desktop: 100),
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noNotificationsYet,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              // White cards with left border indicators
              return RefreshIndicator(
                onRefresh: np.fetchNotifications,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: np.notifications.length,
                  separatorBuilder: (context4, index2) => const SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    final notif = np.notifications[index];
                    return _NotificationTile(
                      notification: notif,
                      onTap: () {
                        if (!notif.read) np.markRead(notif.id);
                        String? courseId = notif.data?.courseId;
                        if ((courseId == null || courseId.isEmpty) &&
                            notif.data?.contexturl != null) {
                          // Decode HTML entities then parse
                          final raw = notif.data!.contexturl!.replaceAll('&amp;', '&');
                          final uri = Uri.tryParse(raw);
                          // user/view.php?id=USER&course=COURSE  prefer 'course' param
                          courseId = uri?.queryParameters['course'] ??
                              uri?.queryParameters['courseid'] ??
                              (uri?.path.contains('/course/') == true
                                  ? uri?.queryParameters['id']
                                  : null);
                        }
                        if (courseId != null && courseId.isNotEmpty) {
                          Navigator.pushNamed(context, '/course-detail',
                              arguments: courseId);
                        }
                      },

                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData _iconFor(String type) {
    switch (type) {
      case 'enrollment':
        return Icons.school_outlined;
      case 'grade':
        return Icons.grade_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'new_course':
        return Icons.library_books_outlined;
      case 'new_content':
        return Icons.play_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type, BuildContext context) {
    // Colors for left border indicators
    // Using bright green #34D399 for dark mode, forest green for light mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final brightGreen = const Color(0xFF34D399);
    final forestGreen = const Color(0xFF1F7A63);
    final goldAccent = const Color(0xFFC59D5F);
    final sageGreen = const Color(0xFF7FBFA6);

    switch (type) {
      case 'enrollment':
        return isDarkMode ? brightGreen : forestGreen;
      case 'grade':
        return goldAccent;
      case 'assignment':
        return isDarkMode ? brightGreen : forestGreen;
      case 'new_course':
        return isDarkMode ? brightGreen : sageGreen;
      case 'new_content':
        return isDarkMode ? brightGreen : forestGreen;
      default:
        return isDarkMode ? const Color(0xFFB4BCC4) : const Color(0xFF6B7280);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode
        ? const Color(0xFF1E3A34)   // Dark green
        : const Color(0xFFEAF5F2); // Light green
    final cardBorderColor =
        isDarkMode ? const Color(0xFF2F4F4F) : const Color(0xFFD1E7E0);
    final iconBgColor = isDarkMode
        ? const Color(0xFF254D45)    // Slightly lighter dark green
        : const Color(0xFFE6F4F1); // Light green
    final textPrimaryColor = isDarkMode
      ? const Color(0xFFF9FAFB)
      : Colors.black87;
    final leftBorderColor = _colorFor(notification.type, context);
    final isUnread = !notification.read;
    final hasCourse = (notification.data?.courseId != null &&
            notification.data!.courseId!.isNotEmpty) ||
        (notification.data?.contexturl != null && (() {
          final raw = notification.data!.contexturl!.replaceAll('&amp;', '&');
          final uri = Uri.tryParse(raw);
          return uri?.queryParameters['course'] != null ||
              uri?.queryParameters['courseid'] != null ||
              (uri?.path.contains('/course/') == true &&
                  uri?.queryParameters['id'] != null);
        })());

    return InkWell(
      onTap: hasCourse ? onTap : (!notification.read ? onTap : null),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: cardBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cardBorderColor, width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: leftBorderColor,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(notification.type),
                    color: leftBorderColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: textPrimaryColor,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notification.type == 'enrollment'
                              ? _formatDate(notification.createdAt)
                              : _timeAgo(notification.createdAt),
                          style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode
                                ? const Color(0xFFB4BCC4)
                                : Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (notification.type == 'enrollment') ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Enrolled on ${_formatDate(notification.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (hasCourse) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.arrow_forward,
                              size: 12,
                              color: isDarkMode
                                  ? const Color(0xFF34D399)
                                  : leftBorderColor),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.viewCourse,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode
                                  ? const Color(0xFF34D399)
                                  : leftBorderColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF34D399)
                          : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
