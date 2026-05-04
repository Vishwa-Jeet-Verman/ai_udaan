import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/enrollment_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/course_card.dart';
import '../../widgets/user_avatar.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<EnrollmentProvider>();
      // Only fetch if we don't already have data (e.g. navigated here after enroll)
      if (provider.enrollments.isEmpty && !provider.isLoading) {
        provider.fetchEnrollments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myCourses),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAvatar(radius: 16, fontSize: 12),
          ),
        ],
      ),
      body: Consumer<EnrollmentProvider>(
        builder: (context, enrollmentProvider, _) {
          final enrollmentsWithCourse = enrollmentProvider.enrollments
              .where((enrollment) => enrollment.course != null)
              .toList();

          if (enrollmentProvider.isLoading &&
              enrollmentProvider.enrollments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (enrollmentProvider.error != null &&
              enrollmentProvider.enrollments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(enrollmentProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => enrollmentProvider.fetchEnrollments(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (enrollmentsWithCourse.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noEnrolledCoursesYet,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.exploreAndEnrollCourses,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final useGrid =
                  constraints.maxWidth >= AppResponsive.tabletBreakpoint;

              if (!useGrid) {
                return RefreshIndicator(
                  onRefresh: () => enrollmentProvider.fetchEnrollments(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: enrollmentsWithCourse.length,
                    itemBuilder: (context, index) {
                      final enrollment = enrollmentsWithCourse[index];
                      final course = enrollment.course;

                      if (course == null) {
                        return const SizedBox.shrink();
                      }

                      return CourseCard(
                        course: course,
                        showEnrolledBadge: true,
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

              final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : 2;

              return RefreshIndicator(
                onRefresh: () => enrollmentProvider.fetchEnrollments(),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: enrollmentsWithCourse.length,
                  itemBuilder: (context, index) {
                    final course = enrollmentsWithCourse[index].course;

                    if (course == null) {
                      return const SizedBox.shrink();
                    }

                    return CourseCard(
                      course: course,
                      showEnrolledBadge: true,
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
          );
        },
      ),
    );
  }
}
