import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/lesson.dart';
import '../../utils/responsive.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 1080,
      desktop: 1320,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: Column(
          children: [
            // Filter chips
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Approved', 'approved'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', 'rejected'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: adminProvider.lessonsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : adminProvider.lessonsError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            adminProvider.lessonsError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => adminProvider.fetchAllLessons(
                              contentStatus: _filterStatus,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : adminProvider.lessons.isEmpty
                  ? const Center(child: Text('No lessons found.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final useGrid =
                            constraints.maxWidth >=
                            AppResponsive.tabletBreakpoint;

                        if (!useGrid) {
                          return RefreshIndicator(
                            onRefresh: () => adminProvider.fetchAllLessons(
                              contentStatus: _filterStatus,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.all(horizontalPadding),
                              itemCount: adminProvider.lessons.length,
                              itemBuilder: (context, index) {
                                return _buildLessonCard(
                                  adminProvider.lessons[index],
                                );
                              },
                            ),
                          );
                        }

                        final crossAxisCount = constraints.maxWidth >= 1200
                            ? 3
                            : 2;

                        return RefreshIndicator(
                          onRefresh: () => adminProvider.fetchAllLessons(
                            contentStatus: _filterStatus,
                          ),
                          child: GridView.builder(
                            padding: EdgeInsets.all(horizontalPadding),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.2,
                                ),
                            itemCount: adminProvider.lessons.length,
                            itemBuilder: (context, index) {
                              return _buildLessonCard(
                                adminProvider.lessons[index],
                                margin: EdgeInsets.zero,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStatus = status);
        context.read<AdminProvider>().fetchAllLessons(contentStatus: status);
      },
    );
  }

  Widget _buildLessonCard(
    Lesson lesson, {
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    Color statusColor;
    switch (lesson.contentStatus) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  lesson.isVideo
                      ? Icons.play_circle_outline
                      : Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    lesson.contentStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lesson.courseTitle != null)
              Text(
                'Course: ${lesson.courseTitle}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              'Type: ${lesson.type.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (lesson.contentStatus == 'pending') ...[
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(lesson.id, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(lesson.id, 'approved'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String lessonId, String contentStatus) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateLessonStatus(
      lessonId,
      contentStatus,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Lesson $contentStatus successfully'
                : adminProvider.lessonsError ?? 'Failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
