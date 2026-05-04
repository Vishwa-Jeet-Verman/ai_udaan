import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';

import '../../utils/responsive.dart';
import '../../widgets/course_card.dart';

class SearchCoursesScreen extends StatefulWidget {
  const SearchCoursesScreen({super.key});

  @override
  State<SearchCoursesScreen> createState() => _SearchCoursesScreenState();
}

class _SearchCoursesScreenState extends State<SearchCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final courseProvider = context.read<CourseProvider>();
    final allCourses = courseProvider.courses;

    // Filter courses by title or description
    final results = allCourses.where((course) {
      final titleMatch = course.title.toLowerCase().contains(
        query.toLowerCase(),
      );
      final descMatch =
          course.description?.toLowerCase().contains(query.toLowerCase()) ??
          false;
      return titleMatch || descMatch;
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          style: Theme.of(context).textTheme.titleMedium,
          onChanged: _performSearch,
          onSubmitted: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: _buildBody(horizontalPadding),
        ),
      ),
    );
  }

  Widget _buildBody(double horizontalPadding) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for courses',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter keywords to find courses',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= AppResponsive.tabletBreakpoint;

        if (!useGrid) {
          return ListView.builder(
            padding: EdgeInsets.all(horizontalPadding),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final course = _searchResults[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CourseCard(
                  course: course,
                  onTap: () {
                    Navigator.pushNamed(context, '/course-detail', arguments: course.id);
                  },
                ),
              );
            },
          );
        }

        final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : 2;

        return GridView.builder(
          padding: EdgeInsets.all(horizontalPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final course = _searchResults[index];
            return CourseCard(
              course: course,
              onTap: () {
                Navigator.pushNamed(context, '/course-detail', arguments: course.id);
              },
            );
          },
        );
      },
    );
  }
}


