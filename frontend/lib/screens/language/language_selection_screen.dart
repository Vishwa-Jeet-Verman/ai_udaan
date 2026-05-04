import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/preferences_provider.dart';
import '../../config/theme.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,           // Deep forest green
              AppTheme.primaryLight,           // Lighter forest green
              AppTheme.secondaryColor,         // Soft sage green
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                if (MediaQuery.of(context).size.height > 600) ...[
                  const Icon(
                    Icons.rocket_launch,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                ],

                // Welcome Text
                const Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI UDAAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),

                // Language Selection Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.language,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Select Your Language',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'अपनी भाषा चुनें',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Language Options
                        ...PreferencesProvider.supportedLanguages.map((lang) {
                          final isEnglish = lang == 'English';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedLanguage = lang;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedLanguage == lang
                                        ? AppTheme.primaryColor
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: _selectedLanguage == lang
                                      ? AppTheme.lightGreen
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _selectedLanguage == lang
                                              ? AppTheme.primaryColor
                                              : Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: _selectedLanguage == lang
                                            ? AppTheme.primaryColor
                                            : Colors.transparent,
                                      ),
                                      child: _selectedLanguage == lang
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedLanguage == lang
                                                ? AppTheme.primaryColor
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          isEnglish ? 'English' : 'हिंदी',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Continue Button
                ElevatedButton(
                  onPressed: _selectedLanguage == null
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final prefsProvider = context.read<PreferencesProvider>();
                          
                          await prefsProvider.setLanguage(_selectedLanguage!);
                          
                          // Mark that language has been selected
                          final prefs = await prefsProvider.getSharedPreferences();
                          await prefs.setBool('language_selected', true);
                          
                          if (!mounted) return;
                          navigator.pushReplacementNamed('/home');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text(
                    'Continue / जारी रखें',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Skip Button
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final prefsProvider = context.read<PreferencesProvider>();
                    
                    await prefsProvider.setLanguage('English');
                    
                    final prefs = await prefsProvider.getSharedPreferences();
                    await prefs.setBool('language_selected', true);
                    
                    if (!mounted) return;
                    navigator.pushReplacementNamed('/home');
                  },
                  child: const Text(
                    'Skip (Default: English)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
