import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/user_avatar.dart';
import '../settings/settings_screen.dart';
// import 'downloads_screen.dart'; // re-enable when downloads is ready
import 'grades_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final l10n = AppLocalizations.of(context)!;
    final horizontalPadding = AppResponsive.horizontalPadding(
      context, mobile: 0, tablet: 8, desktop: 16,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context, tablet: 800, desktop: 920,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.more),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAvatar(radius: 16, fontSize: 12),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            children: [
              // Downloads temporarily disabled
              _MoreMenuItem(
                icon: Icons.download_outlined,
                title: l10n.downloads,
                subtitle: l10n.downloadsSubtitle,
                enabled: false,
                onTap: () {},
              ),
              const Divider(height: 1),
              _MoreMenuItem(
                icon: Icons.grade_outlined,
                title: l10n.gradesTitle,
                subtitle: isLoggedIn ? l10n.gradesSubtitleLoggedIn : l10n.loginRequiredLabel,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GradesScreen()),
                ),
              ),
              const Divider(height: 1),
              _MoreMenuItem(
                icon: Icons.settings_outlined,
                title: l10n.appSettings,
                subtitle: l10n.appSettingsSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const Divider(height: 1),

              // Login / Logout
              if (isLoggedIn)
                _MoreMenuItem(
                  icon: Icons.logout,
                  title: l10n.logout,
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.logoutConfirmTitle),
                        content: Text(l10n.logoutConfirmContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(l10n.logout,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      // Clear enrollment data
                      context.read<EnrollmentProvider>().clearEnrollments();
                      // Logout
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/', (route) => false);
                      }
                    }
                  },
                )
              else
                _MoreMenuItem(
                  icon: Icons.login,
                  title: l10n.signInTitle,
                  iconColor: const Color(0xFF1E3A5F),
                  textColor: const Color(0xFF1E3A5F),
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool enabled;

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = enabled ? null : Colors.grey[400];
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: enabled ? (iconColor ?? Colors.grey[700]) : Colors.grey[400], size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: effectiveColor ?? textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  fontSize: 13,
                  color: enabled
                      ? (isDark ? Colors.grey[500] : Colors.grey[600])
                      : Colors.grey[400]))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: enabled ? onTap : null,
    );
  }
}
