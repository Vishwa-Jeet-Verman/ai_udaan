import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/course_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/course_card.dart';

class CourseListScreen extends StatelessWidget {
  final bool filterFree;
  const CourseListScreen({super.key, this.filterFree = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(filterFree ? 'Free Courses' : AppLocalizations.of(context)!.browseAllCourses)),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, _) {
          if (courseProvider.isLoading && courseProvider.courses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseProvider.error != null && courseProvider.courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(courseProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => courseProvider.fetchCourses(refresh: true),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          final courses = filterFree
              ? courseProvider.courses.where((c) => c.isFree).toList()
              : courseProvider.courses;

          if (courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filterFree ? Icons.card_giftcard : Icons.school_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filterFree
                        ? 'No free courses available'
                        : AppLocalizations.of(context)!.noCoursesFoundMsg,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                  onRefresh: () => courseProvider.fetchCourses(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return CourseCard(
                        course: course,
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
                onRefresh: () => courseProvider.fetchCourses(refresh: true),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return CourseCard(
                      course: course,
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
