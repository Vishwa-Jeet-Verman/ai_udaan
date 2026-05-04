import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../models/course.dart';
import '../../utils/responsive.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/language_switcher.dart';
import '../courses/course_list_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchFieldLayerLink = LayerLink();
  final Object _searchTapRegionGroup = Object();
  final ScrollController _searchResultsScrollController = ScrollController();
  List<Course> _searchResults = [];
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchResultsScrollController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

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
    });
  }

  void _closeSearch() {
    if (!_isSearching) {
      return;
    }

    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    _searchFocusNode.unfocus();
  }

  void _openSearch() {
    if (_isSearching) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.displayName ?? 'Student';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletLayout = AppResponsive.isTablet(context);
    final greetingName = screenWidth < 430
        ? userName.split(' ').first
        : userName;
    final showGreeting = screenWidth >= 360;
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 16,
      tablet: 20,
      desktop: 24,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 960,
      desktop: 1240,
    );
    final searchFieldWidth = (screenWidth * (isTabletLayout ? 0.34 : 0.46))
        .clamp(190.0, isTabletLayout ? 340.0 : 260.0)
        .toDouble();
    final searchButtonWidth = (isTabletLayout ? 152.0 : 124.0).clamp(
      112.0,
      searchFieldWidth,
    );
    final hasQuery = _searchController.text.trim().isNotEmpty;

    final searchButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Theme.of(context).dividerColor),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    Widget buildHeaderSearchControl({required double width}) {
      return CompositedTransformTarget(
        link: _searchFieldLayerLink,
        child: SizedBox(
          width: width,
          child: _isSearching
              ? TextField(
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  onChanged: _performSearch,
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchCourses,
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.4,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _closeSearch,
                    ),
                  ),
                )
              : SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _openSearch,
                    style: searchButtonStyle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.search,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.dashboard,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Greeting
          if (showGreeting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTabletLayout ? 220 : 140,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.waving_hand,
                      color: Color(0xFFFFD700),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: isTabletLayout ? 188 : 108,
                      child: Text(
                        AppLocalizations.of(context)!.helloUser(greetingName),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Language switcher
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: LanguageSwitcher(iconSize: 22),
          ),
          // Profile menu
          PopupMenuButton<String>(
            tooltip: 'Profile',
            offset: const Offset(0, 50),
            child: const Padding(
              padding: EdgeInsets.only(right: 12, left: 8),
              child: UserAvatar(radius: 16, fontSize: 12, interactive: false),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  break;
                case 'my_courses':
                  Navigator.pushNamed(context, '/my-courses');
                  break;
                case 'login':
                  Navigator.pushNamed(context, '/login');
                  break;
                case 'logout':
                  // Clear enrollment data
                  context.read<EnrollmentProvider>().clearEnrollments();
                  // Logout
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              final authProvider = context.read<AuthProvider>();
              final isLoggedIn = authProvider.isLoggedIn;

              return [
                PopupMenuItem(
                  value: 'profile',
                  enabled: isLoggedIn,
                  child: SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 20,
                          color: isLoggedIn ? null : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.myProfile,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isLoggedIn ? null : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'my_courses',
                  enabled: isLoggedIn,
                  child: SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 20,
                          color: isLoggedIn ? null : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.myCourses,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isLoggedIn ? null : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                if (isLoggedIn)
                  PopupMenuItem(
                    value: 'logout',
                    child: SizedBox(
                      width: 140,
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.logout2, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)),
                        ],
                      ),
                    ),
                  )
                else
                  PopupMenuItem(
                    value: 'login',
                    child: SizedBox(
                      width: 140,
                      child: Row(
                        children: [
                          Icon(Icons.login, size: 20, color: const Color(0xFF1F7A63)),
                          SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.login, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF1F7A63))),
                        ],
                      ),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              final courseProvider = context.read<CourseProvider>();
              final authProvider = context.read<AuthProvider>();
              final enrollmentProvider = context.read<EnrollmentProvider>();
              await courseProvider.fetchCourses(refresh: true);
              if (authProvider.isLoggedIn) {
                await enrollmentProvider.fetchEnrollments();
              }
            },
            child: SingleChildScrollView(
              physics: _isSearching
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ─── Featured Courses + Search (same row) ─────────
                      TapRegion(
                        groupId: _searchTapRegionGroup,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const leadingAndGapsWidth = 22.0 + 8.0 + 8.0;
                              final maxSearchWidth =
                                  (constraints.maxWidth - leadingAndGapsWidth)
                                      .clamp(0.0, searchFieldWidth)
                                      .toDouble();
                              final headerSearchWidth = _isSearching
                                  ? maxSearchWidth
                                  : searchButtonWidth
                                        .clamp(0.0, maxSearchWidth)
                                        .toDouble();

                              return Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.featuredCourses,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  buildHeaderSearchControl(
                                    width: headerSearchWidth,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      _FeaturedCoursesCarousel(),

                      const SizedBox(height: 24),

                      // ─── Quick Stats Row ──────────────────────────
                      _QuickStatsRow(),

                      const SizedBox(height: 16),

                      // ─── Category Filter ──────────────────────────
                      _SectionTitle(
                        title: AppLocalizations.of(context)!.categories,
                        icon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 12),
                      _CategoryFilter(
                        selected: _selectedCategory,
                        onSelected: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),

                      const SizedBox(height: 24),

                      // Removed My Enrolled Courses section

                      // ─── Browse All Courses ───────────────────────
                      _SectionTitle(
                        title: AppLocalizations.of(context)!.browseAllCourses,
                        icon: Icons.explore_outlined,
                      ),
                      const SizedBox(height: 12),
                      _AllCoursesList(category: _selectedCategory),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Invisible barrier to close search on tap outside
          if (_isSearching)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSearch,
                child: Container(color: Colors.transparent),
              ),
            ),

          if (_isSearching && hasQuery)
            CompositedTransformFollower(
              link: _searchFieldLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: IgnorePointer(
                ignoring: false,
                child: TapRegion(
                  groupId: _searchTapRegionGroup,
                  child: SizedBox(
                    width: searchFieldWidth,
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      elevation: 10,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: _calculateOverlayHeight(context),
                        child: _searchResults.isEmpty
                            ? _buildNoResults(compact: true)
                            : _buildResultsList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateOverlayHeight(BuildContext context) {
    if (_searchResults.isEmpty) {
      return 150;
    }

    const int maxVisibleItems = 4;
    const double estimatedItemHeight = 106;
    const double listVerticalPadding = 24;
    final int visibleCount = _searchResults.length.clamp(1, maxVisibleItems);
    final double desiredHeight =
        listVerticalPadding + (visibleCount * estimatedItemHeight);
    final double maxHeight = (MediaQuery.of(context).size.height * 0.6);

    return desiredHeight < maxHeight ? desiredHeight : maxHeight;
  }

  Widget _buildNoResults({bool compact = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: compact ? 40 : 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: compact ? 8 : 16),
          Text(
            l10n.noCoursesFoundMsg,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            l10n.tryDifferentKeywordsMsg,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Scrollbar(
      controller: _searchResultsScrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _searchResultsScrollController,
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: null,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final course = _searchResults[index];
          return _SearchResultCard(
            course: course,
            onTap: () {
              _closeSearch(); // Close search when selecting a course
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Result Card
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _SearchResultCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    course.thumbnailUrl != null &&
                        course.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        course.thumbnailUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (course.description != null &&
                        course.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (course.price > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\u20B9${course.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F7A63).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.free,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: const Color(0xFF1F7A63),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.school, size: 32, color: Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Filter
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  static const _categories = ['All', 'Basic', 'Advanced'];

  static const _icons = {
    'All': Icons.apps_rounded,
    'Basic': Icons.star_border_rounded,
    'Advanced': Icons.bolt_rounded,
  };

  static const _colors = {
    'All': Color(0xFF2B6CB0),
    'Basic': Color(0xFF38A169),
    'Advanced': Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Map<String, String> labels = {
      'All': l10n.all,
      'Basic': l10n.basic,
      'Advanced': l10n.advanced,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = selected == cat;
          final color = _colors[cat]!;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelected(cat),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.1),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _icons[cat]!,
                      color: isSelected ? Colors.white : color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[cat] ?? cat,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Stats
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<EnrollmentProvider, CourseProvider>(
      builder: (context, enrollProv, courseProv, _) {
        final enrolledCount = enrollProv.enrollments.length;
        final totalCourses = courseProv.courses.length;
        final freeCourses = courseProv.courses.where((c) => c.isFree).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.school,
                  label: AppLocalizations.of(context)!.enrolled,
                  value: '$enrolledCount',
                  color: const Color(0xFF1E3A5F),
                  onTap: () {
                    Navigator.pushNamed(context, '/my-courses');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.library_books,
                  label: AppLocalizations.of(context)!.availableLabel,
                  value: '$totalCourses',
                  color: const Color(0xFF2B6CB0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CourseListScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.card_giftcard,
                  label: AppLocalizations.of(context)!.free,
                  value: '$freeCourses',
                  color: const Color(0xFF38A169),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CourseListScreen(filterFree: true),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Courses — Horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────
// This element is currently unused but kept for future use.
// Ignore analyzer warning about it being unused for now.
// ignore: unused_element
class _MyCoursesHorizontalList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EnrollmentProvider>(
      builder: (context, enrollProv, _) {
        final enrolled = enrollProv.enrollments
            .where((e) => e.course != null)
            .toList();

        if (enrollProv.isLoading && enrolled.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (enrolled.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.myCourses,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.noEnrolledCourses,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.exploreAndEnroll,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
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
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: enrolled.length,
                  itemBuilder: (context, i) {
                    final course = enrolled[i].course!;
                    return _EnrolledCourseCard(course: course);
                  },
                ),
              );
            }

            final columns = constraints.maxWidth >= 1100 ? 3 : 2;
            const spacing = 14.0;
            final itemWidth =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (int i = 0; i < enrolled.length; i++)
                    SizedBox(
                      width: itemWidth,
                      child: _EnrolledCourseCard(
                        course: enrolled[i].course!,
                        width: double.infinity,
                        margin: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EnrolledCourseCard extends StatelessWidget {
  final Course course;
  final double width;
  final EdgeInsetsGeometry margin;

  const _EnrolledCourseCard({
    required this.course,
    this.width = 240,
    this.margin = const EdgeInsets.only(right: 14),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/course-detail', arguments: course.id);
      },
      child: Container(
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFEAF5F2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: course.thumbnailUrl != null
                  ? Image.network(
                      course.thumbnailUrl!,
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 95,
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.school,
                          color: AppTheme.primaryColor,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      height: 95,
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.school,
                        color: AppTheme.primaryColor,
                        size: 40,
                      ),
                    ),
            ),
            // Title + badge
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.enrolled,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Courses — PageView carousel
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCoursesCarousel extends StatefulWidget {
  @override
  State<_FeaturedCoursesCarousel> createState() =>
      _FeaturedCoursesCarouselState();
}

class _FeaturedCoursesCarouselState extends State<_FeaturedCoursesCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        // Get the total number of pages from the provider
        final courseProv = context.read<CourseProvider>();
        final totalPages = courseProv.courses.take(4).length;

        if (totalPages > 1) {
          final nextPage = (_currentPage + 1) % totalPages;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProv, _) {
        final featured = courseProv.courses.take(4).toList();
        if (featured.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: featured.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  return _FeaturedCard(course: featured[i]);
                },
              ),
            ),
            const SizedBox(height: 10),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                featured.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: i == _currentPage ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Course course;
  const _FeaturedCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/course-detail', arguments: course.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background fill layer (removes empty side gaps)
              if (course.thumbnailUrl != null &&
                  course.thumbnailUrl!.isNotEmpty)
                Image.network(
                  course.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppTheme.primaryColor),
                )
              else
                Container(color: AppTheme.primaryColor),
              // Subtle mask so the overlaid full image and text remain readable
              Container(color: Colors.black.withValues(alpha: 0.10)),
              // Foreground full image layer (keeps the entire image visible)
              if (course.thumbnailUrl != null &&
                  course.thumbnailUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Image.network(
                    course.thumbnailUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              // Dark overlay for text visibility
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: course.isFree
                            ? const Color(0xFF38A169)
                            : const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.isFree
                            ? AppLocalizations.of(context)!.free
                            : '₹${course.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (course.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All Courses — Vertical list
// ─────────────────────────────────────────────────────────────────────────────
class _AllCoursesList extends StatelessWidget {
  final String category;

  const _AllCoursesList({this.category = 'All'});

  List<Course> _filter(List<Course> courses) {
    if (category == 'All') return courses;
    return courses.where((c) {
      // Use level field if available, otherwise fall back to price-based heuristic
      if (c.level != null) {
        return c.level!.toLowerCase() == category.toLowerCase();
      }
      // Fallback: Basic = free, Advanced = paid
      if (category == 'Basic') return c.isFree;
      if (category == 'Advanced') return !c.isFree;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, courseProv, _) {
        final courses = _filter(courseProv.courses);

        if (courseProv.isLoading && courseProv.courses.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (courses.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(child: Text(AppLocalizations.of(context)!.noCoursesFoundMsg)),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final useGrid =
                constraints.maxWidth >= AppResponsive.tabletBreakpoint;

            if (!useGrid) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: courses.length,
                itemBuilder: (context, i) {
                  final course = courses[i];
                  return _CourseListTile(course: course);
                },
              );
            }

            final crossAxisCount = constraints.maxWidth >= 1100 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.9,
              ),
              itemCount: courses.length,
              itemBuilder: (context, i) {
                final course = courses[i];
                return _CourseListTile(course: course, showBottomMargin: false);
              },
            );
          },
        );
      },
    );
  }
}

class _CourseListTile extends StatelessWidget {
  final Course course;
  final bool showBottomMargin;

  const _CourseListTile({required this.course, this.showBottomMargin = true});

  @override
  Widget build(BuildContext context) {
    final isEnrolled = context.watch<EnrollmentProvider>().isEnrolledIn(
      course.id,
    );

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/course-detail', arguments: course.id);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: showBottomMargin ? 12 : 0),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5F2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: course.thumbnailUrl != null
                  ? Image.network(
                      course.thumbnailUrl!,
                      width: 100,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 100,
                        height: 90,
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.school,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 90,
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.school,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
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
                            color: course.isFree
                                ? const Color(
                                    0xFF38A169,
                                  ).withValues(alpha: 0.12)
                                : const Color(
                                    0xFFE67E22,
                                  ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            course.isFree
                                ? AppLocalizations.of(context)!.free
                                : '₹${course.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: course.isFree
                                  ? const Color(0xFF38A169)
                                  : const Color(0xFFE67E22),
                            ),
                          ),
                        ),
                        if (isEnrolled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F7A63).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${AppLocalizations.of(context)!.enrolled} ✓',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F7A63),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
