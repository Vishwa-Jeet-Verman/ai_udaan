import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/preferences_provider.dart';
import '../l10n/app_localizations.dart';
import '../config/theme.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showLabel;
  final double iconSize;

  const LanguageSwitcher({
    super.key,
    this.showLabel = true,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final prefsProvider = context.watch<PreferencesProvider>();
    final currentLanguage = prefsProvider.language;
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.language,
        size: iconSize,
      ),
      tooltip: l10n?.language ?? 'Language',
      onSelected: (String language) async {
        await prefsProvider.setLanguage(language);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.languageChanged(language) ?? 'Language changed to $language',
              ),
              backgroundColor: AppTheme.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return PreferencesProvider.supportedLanguages.map((String language) {
          final isSelected = language == currentLanguage;
          return PopupMenuItem<String>(
            value: language,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : null,
                      ),
                    ),
                    Text(
                      language == 'English' ? 'English' : 'हिंदी',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
