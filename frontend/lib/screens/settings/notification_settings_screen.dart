import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/preferences_provider.dart';
import '../../utils/responsive.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.watch<PreferencesProvider>();
    final horizontalPadding = AppResponsive.horizontalPadding(
      context, mobile: 0, tablet: 8, desktop: 16,
    );
    final contentMaxWidth = AppResponsive.contentMaxWidth(
      context, tablet: 860, desktop: 980,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notificationSettings,
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

              _SectionHeader(title: l10n.general),
              _NotifTile(
                title: l10n.pushNotifications,
                subtitle: l10n.pushNotificationsSubtitle,
                value: prefs.pushNotifications,
                onChanged: (v) => prefs.setNotification('push', v),
              ),
              _NotifTile(
                title: l10n.emailNotifications,
                subtitle: l10n.emailNotificationsSubtitle,
                value: prefs.emailNotifications,
                onChanged: (v) => prefs.setNotification('email', v),
              ),

              const Divider(height: 1),

              _SectionHeader(title: l10n.courseNotifications),
              _NotifTile(
                title: l10n.courseUpdates,
                subtitle: l10n.courseUpdatesSubtitle,
                value: prefs.courseUpdates,
                onChanged: (v) => prefs.setNotification('courseUpdates', v),
              ),
              _NotifTile(
                title: l10n.newLessons,
                subtitle: l10n.newLessonsSubtitle,
                value: prefs.newLessons,
                onChanged: (v) => prefs.setNotification('newLessons', v),
              ),
              _NotifTile(
                title: l10n.assignments,
                subtitle: l10n.assignmentsSubtitle,
                value: prefs.assignments,
                onChanged: (v) => prefs.setNotification('assignments', v),
              ),
              _NotifTile(
                title: l10n.grades,
                subtitle: l10n.gradesSubtitle,
                value: prefs.grades,
                onChanged: (v) => prefs.setNotification('grades', v),
              ),

              const Divider(height: 1),

              _SectionHeader(title: l10n.communication),
              _NotifTile(
                title: l10n.announcements,
                subtitle: l10n.announcementsSubtitle,
                value: prefs.announcements,
                onChanged: (v) => prefs.setNotification('announcements', v),
              ),
              _NotifTile(
                title: l10n.messagesNotif,
                subtitle: l10n.messagesNotifSubtitle,
                value: prefs.messages,
                onChanged: (v) => prefs.setNotification('messages', v),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.notificationsSaved),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.savePreferences,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
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

class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[500]
              : Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF4A90E2),
    );
  }
}
