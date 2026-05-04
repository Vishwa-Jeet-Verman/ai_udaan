import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'l10n/app_localizations.dart';

import 'config/theme.dart';
import 'config/smooth_scroll_behavior.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/enrollment_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/preferences_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/courses/course_detail_screen.dart';
import 'screens/lessons/lesson_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verify_screen.dart';
import 'screens/enrollments/my_courses_screen.dart';
import 'screens/language/language_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const LmsApp());
}

class LmsApp extends StatelessWidget {
  const LmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        // AdminProvider removed — student-only app
      ],
      child: Consumer2<ThemeProvider, PreferencesProvider>(
        builder: (context, themeProvider, prefsProvider, _) {
          return MaterialApp(
            scrollBehavior: AppSmoothScrollBehavior(),
            title: 'AI UDAAN',
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)?.appTitle ?? 'AI UDAAN',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: prefsProvider.locale,
            supportedLocales: const [Locale('en'), Locale('hi')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/language-selection': (context) => const LanguageSelectionScreen(),
              '/home': (context) => const HomeScreen(),
              '/my-courses': (context) => const MyCoursesScreen(),
            },
            onGenerateRoute: (settings) {
              // Login route with optional role argument
              if (settings.name == '/login') {
                return MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                  settings: settings,
                );
              }
              // Register route with optional role argument
              if (settings.name == '/register') {
                return MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                  settings: settings,
                );
              }

              // OTP verification route
              if (settings.name == '/otp-verify') {
                return MaterialPageRoute(
                  builder: (_) => const OtpVerifyScreen(),
                  settings: settings,
                );
              }

              // Forgot password route
              if (settings.name == '/forgot-password') {
                return MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen(),
                );
              }

              // Course detail route
              if (settings.name == '/course-detail') {
                final courseId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(courseId: courseId),
                );
              }

              // Lesson route
              if (settings.name == '/lesson') {
                final lessonId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => LessonScreen(lessonId: lessonId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
