import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/course.dart';
import '../../utils/responsive.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key});

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
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
              child: adminProvider.coursesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : adminProvider.coursesError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            adminProvider.coursesError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => adminProvider.fetchAllCourses(
                              status: _filterStatus,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : adminProvider.courses.isEmpty
                  ? const Center(child: Text('No courses found.'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final useGrid =
                            constraints.maxWidth >=
                            AppResponsive.tabletBreakpoint;

                        if (!useGrid) {
                          return RefreshIndicator(
                            onRefresh: () => adminProvider.fetchAllCourses(
                              status: _filterStatus,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.all(horizontalPadding),
                              itemCount: adminProvider.courses.length,
                              itemBuilder: (context, index) {
                                return _buildCourseCard(
                                  adminProvider.courses[index],
                                );
                              },
                            ),
                          );
                        }

                        final crossAxisCount = constraints.maxWidth >= 1200
                            ? 3
                            : 2;

                        return RefreshIndicator(
                          onRefresh: () => adminProvider.fetchAllCourses(
                            status: _filterStatus,
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
                            itemCount: adminProvider.courses.length,
                            itemBuilder: (context, index) {
                              return _buildCourseCard(
                                adminProvider.courses[index],
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
        context.read<AdminProvider>().fetchAllCourses(status: status);
      },
    );
  }

  Widget _buildCourseCard(
    Course course, {
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    Color statusColor;
    switch (course.status) {
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
                Expanded(
                  child: Text(
                    course.title,
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
                    course.status.toUpperCase(),
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
            if (course.creatorName != null)
              Text(
                'By: ${course.creatorName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Text(
              'Price: ${course.priceDisplay}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (course.status == 'pending') ...[
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(course.id, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(course.id, 'approved'),
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

  Future<void> _updateStatus(String courseId, String status) async {
    final adminProvider = context.read<AdminProvider>();
    final success = await adminProvider.updateCourseStatus(courseId, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Course $status successfully'
                : adminProvider.coursesError ?? 'Failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
