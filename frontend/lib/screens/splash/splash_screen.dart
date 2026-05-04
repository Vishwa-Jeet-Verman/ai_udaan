import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/preferences_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final prefsProvider = context.read<PreferencesProvider>();
    
    await authProvider.tryAutoLogin();
    
    if (!mounted) return;
    
    // Check if language has been selected
    final prefs = await prefsProvider.getSharedPreferences();
    final languageSelected = prefs.getBool('language_selected') ?? false;
    
    if (!mounted) return;
    
    if (!languageSelected) {
      Navigator.pushReplacementNamed(context, '/language-selection');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Dark blue-black to match the image
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen background image — covers all screen sizes
            Image.asset(
              'assets/splash_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image not found
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0A1628),
                        const Color(0xFF1F3A5F),
                        const Color(0xFF2D5F8D),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          size: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'AI UDAAN',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'BOOTCAMP',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Loading spinner at the bottom
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.08,
              left: 0,
              right: 0,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00FFB3), // Bright green to match the image
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
