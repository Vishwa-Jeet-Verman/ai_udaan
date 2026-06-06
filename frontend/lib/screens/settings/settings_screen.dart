import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../utils/responsive.dart';
import '../../config/theme.dart';
import '../profile/profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final prefsProvider = context.watch<PreferencesProvider>();
    final isDark = themeProvider.isDarkMode;
    final horizontalPadding = AppResponsive.horizontalPadding(
      context, mobile: 0, tablet: 8, desktop: 16,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context, tablet: 900, desktop: 1000,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            children: [
              const SizedBox(height: 8),

              _SectionHeader(title: l10n.appearance),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: l10n.theme,
                subtitle: isDark ? l10n.darkMode : l10n.lightMode,
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ),

              const Divider(height: 1),

              _SectionHeader(title: l10n.account),
              _SettingsTile(
                icon: Icons.person_outline,
                title: l10n.profile,
                subtitle: authProvider.user?.email ?? '',
                enabled: authProvider.isLoggedIn,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: l10n.changePassword,
                subtitle: authProvider.isLoggedIn ? null : l10n.loginRequiredLabel,
                enabled: authProvider.isLoggedIn,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                ),
              ),

              const Divider(height: 1),

              _SectionHeader(title: l10n.preferences),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: l10n.notifications,
                subtitle: l10n.manageNotifications,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.language_outlined,
                title: l10n.language,
                subtitle: prefsProvider.language,
                onTap: () => _showLanguageDialog(context, l10n, prefsProvider),
              ),

              const Divider(height: 1),

              _SectionHeader(title: l10n.about),
              _SettingsTile(
                icon: Icons.info_outline,
                title: l10n.aboutApp,
                subtitle: l10n.version,
                onTap: () => _showAboutDialog(context, l10n),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                ),
              ),

              if (authProvider.isLoggedIn) ...[
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.logout,
                  title: l10n.logoutLabel,
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _showLogoutDialog(context, l10n),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.aboutDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aboutVersion),
            const SizedBox(height: 8),
            Text(l10n.aboutDescription),
            const SizedBox(height: 8),
            Text(l10n.aboutCopyright),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    AppLocalizations l10n,
    PreferencesProvider prefsProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        String selected = prefsProvider.language;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(l10n.selectLanguage),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: PreferencesProvider.supportedLanguages.map((lang) {
                  final isSelected = selected == lang;
                  return InkWell(
                    onTap: () {
                      setDialogState(() => selected = lang);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppTheme.primaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            lang,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryColor : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  await prefsProvider.setLanguage(selected);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.languageChanged(selected)),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(l10n.apply),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logoutLabel),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              // Capture navigator and providers before awaiting to avoid
              // using `BuildContext` across async gaps.
              final navigator = Navigator.of(context);
              final enrollmentProv = context.read<EnrollmentProvider>();
              final authProv = context.read<AuthProvider>();

              navigator.pop();
              enrollmentProv.clearEnrollments();
              await authProv.logout();

              // Use the captured navigator to push replacement.
              navigator.pushReplacementNamed('/login');
            },
            child: Text(l10n.logoutLabel,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled
            ? (iconColor ?? (isDark ? Colors.grey[400] : Colors.grey[700]))
            : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: enabled ? titleColor : Colors.grey,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: enabled
                    ? (isDark ? Colors.grey[500] : Colors.grey[600])
                    : Colors.grey,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null && enabled
              ? Icon(Icons.chevron_right,
                  color: isDark ? Colors.grey[600] : Colors.grey[400])
              : null),
      onTap: enabled ? onTap : null,
    );
  }
}
