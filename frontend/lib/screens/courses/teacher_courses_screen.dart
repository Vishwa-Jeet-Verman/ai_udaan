import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../utils/responsive.dart';

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  List<Course> _myCourses = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final courses = await context.read<CourseProvider>().fetchMyCourses();
    if (mounted) {
      setState(() {
        _myCourses = courses;
        _isLoading = false;
      });
    }
  }

  List<Course> get _filteredCourses {
    if (_filter == 'all') return _myCourses;
    return _myCourses.where((c) => c.status == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF1F7A63);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 1040,
      desktop: 1240,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCourses),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildChip('Approved', 'approved'),
                    const SizedBox(width: 8),
                    _buildChip('Rejected', 'rejected'),
                  ],
                ),
              ),

              // Course list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _myCourses.isEmpty
                                  ? 'No courses yet.\nTap "New Course" to create one!'
                                  : 'No $_filter courses.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final useGrid =
                              constraints.maxWidth >=
                              AppResponsive.tabletBreakpoint;

                          if (!useGrid) {
                            return RefreshIndicator(
                              onRefresh: _loadCourses,
                              child: ListView.builder(
                                padding: EdgeInsets.all(horizontalPadding),
                                itemCount: _filteredCourses.length,
                                itemBuilder: (context, index) {
                                  final course = _filteredCourses[index];
                                  return _CourseCard(
                                    course: course,
                                    statusColor: _statusColor(course.status),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/course-detail',
                                        arguments: course.id,
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          }

                          final crossAxisCount = constraints.maxWidth >= 1100
                              ? 3
                              : 2;

                          return RefreshIndicator(
                            onRefresh: _loadCourses,
                            child: GridView.builder(
                              padding: EdgeInsets.all(horizontalPadding),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.3,
                                  ),
                              itemCount: _filteredCourses.length,
                              itemBuilder: (context, index) {
                                final course = _filteredCourses[index];
                                return _CourseCard(
                                  course: course,
                                  statusColor: _statusColor(course.status),
                                  margin: EdgeInsets.zero,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/course-detail',
                                      arguments: course.id,
                                    );
                                  },
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
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Color statusColor;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const _CourseCard({
    required this.course,
    required this.statusColor,
    required this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: course.thumbnailUrl != null
                    ? Image.network(
                        course.thumbnailUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.school, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          course.price == 0
                              ? 'Free'
                              : '\u20B9${course.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
