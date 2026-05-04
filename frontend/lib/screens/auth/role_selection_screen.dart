import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTabletLayout = AppResponsive.isTablet(context);
    final horizontalPadding = AppResponsive.horizontalPadding(
      context,
      mobile: 20,
      tablet: 32,
      desktop: 40,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context,
      tablet: 980,
      desktop: 1120,
    );

    final roleCards = [
      _RoleCard(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Admin',
        subtitle: 'Manage courses, users & transactions',
        color: const Color(0xFFE53935),
        onTap: () => Navigator.pushNamed(context, '/login', arguments: 'admin'),
      ),
      _RoleCard(
        icon: Icons.menu_book_rounded,
        title: 'Student',
        subtitle: 'Browse & enroll in courses',
        color: const Color(0xFF1E88E5),
        onTap: () =>
            Navigator.pushNamed(context, '/login', arguments: 'student'),
      ),
      _RoleCard(
        icon: Icons.video_library_rounded,
        title: 'Faculty / Teacher',
        subtitle: 'Upload lectures, notes & manage courses',
        color: const Color(0xFF43A047),
        onTap: () =>
            Navigator.pushNamed(context, '/login', arguments: 'teacher'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                24,
              ),
              child: Column(
                children: [
                  // Logo
                  Icon(
                    Icons.school_rounded,
                    size: AppResponsive.adaptiveSize(
                      context,
                      mobile: 84,
                      tablet: 96,
                      desktop: 104,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI UDAAN',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to continue',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (!isTabletLayout)
                    Column(
                      children: [
                        roleCards[0],
                        const SizedBox(height: 16),
                        roleCards[1],
                        const SizedBox(height: 16),
                        roleCards[2],
                      ],
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1000 ? 3 : 2;
                        const spacing = 16.0;
                        final cardWidth =
                            (constraints.maxWidth - (spacing * (columns - 1))) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: roleCards
                              .map(
                                (card) =>
                                    SizedBox(width: cardWidth, child: card),
                              )
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
