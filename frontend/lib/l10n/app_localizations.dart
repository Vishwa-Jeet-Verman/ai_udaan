import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI UDAAN'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to access this feature.'**
  String get pleaseSignIn;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmContent;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @loginRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequiredLabel;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @manageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get manageNotifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutLabel;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language set to {lang}'**
  String languageChanged(String lang);

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications on this device'**
  String get pushNotificationsSubtitle;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @emailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications via email'**
  String get emailNotificationsSubtitle;

  /// No description provided for @courseNotifications.
  ///
  /// In en, this message translates to:
  /// **'Course Notifications'**
  String get courseNotifications;

  /// No description provided for @courseUpdates.
  ///
  /// In en, this message translates to:
  /// **'Course Updates'**
  String get courseUpdates;

  /// No description provided for @courseUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates about enrolled courses'**
  String get courseUpdatesSubtitle;

  /// No description provided for @newLessons.
  ///
  /// In en, this message translates to:
  /// **'New Lessons'**
  String get newLessons;

  /// No description provided for @newLessonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When new lessons are added'**
  String get newLessonsSubtitle;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @assignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment reminders and deadlines'**
  String get assignmentsSubtitle;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @gradesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When grades are posted'**
  String get gradesSubtitle;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @announcementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important announcements from instructors'**
  String get announcementsSubtitle;

  /// No description provided for @messagesNotif.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesNotif;

  /// No description provided for @messagesNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct messages from instructors'**
  String get messagesNotifSubtitle;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @notificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences saved'**
  String get notificationsSaved;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved lessons & materials'**
  String get downloadsSubtitle;

  /// No description provided for @gradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get gradesTitle;

  /// No description provided for @gradesSubtitleLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'View your course progress'**
  String get gradesSubtitleLoggedIn;

  /// No description provided for @appSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, notifications, account'**
  String get appSettingsSubtitle;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @myCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get myCourses;

  /// No description provided for @featuredCourses.
  ///
  /// In en, this message translates to:
  /// **'Featured Courses'**
  String get featuredCourses;

  /// No description provided for @searchCourses.
  ///
  /// In en, this message translates to:
  /// **'Search courses...'**
  String get searchCourses;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCoursesFound;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @browseAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Browse All Courses'**
  String get browseAllCourses;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String hello(String name);

  /// No description provided for @aboutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About AI UDAAN'**
  String get aboutDialogTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: 1.0.0'**
  String get aboutVersion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive Learning Management System'**
  String get aboutDescription;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 AI UDAAN. All rights reserved.'**
  String get aboutCopyright;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue learning'**
  String get signInToContinue;

  /// No description provided for @loginWith.
  ///
  /// In en, this message translates to:
  /// **'Login with:'**
  String get loginWith;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterYourUsername;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @startLearning.
  ///
  /// In en, this message translates to:
  /// **'Start your learning journey'**
  String get startLearning;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to'**
  String get verificationCodeSent;

  /// No description provided for @verifyAndCreate.
  ///
  /// In en, this message translates to:
  /// **'Verify & Create Account'**
  String get verifyAndCreate;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address.\nWe\'ll send a reset code along with your username.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetCode.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Code'**
  String get sendResetCode;

  /// No description provided for @checkEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkEmailTitle;

  /// No description provided for @checkEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to\n{email}\n\nThe email also includes your username.'**
  String checkEmailSubtitle(String email);

  /// No description provided for @resetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset Code'**
  String get resetCode;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPassword;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong new password for your account.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordReset.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get passwordReset;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.\nYou can now sign in with your new password.'**
  String get passwordResetSuccess;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloUser(String name);

  /// No description provided for @logout2.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout2;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @noCoursesFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCoursesFoundMsg;

  /// No description provided for @tryDifferentKeywordsMsg.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tryDifferentKeywordsMsg;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrolled;

  /// No description provided for @enrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get enrolledCourses;

  /// No description provided for @noEnrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'No enrolled courses'**
  String get noEnrolledCourses;

  /// No description provided for @exploreAndEnroll.
  ///
  /// In en, this message translates to:
  /// **'Explore courses to start learning'**
  String get exploreAndEnroll;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @starred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get starred;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @noStarredMessages.
  ///
  /// In en, this message translates to:
  /// **'No starred messages yet.\nLong-press any message to star it.'**
  String get noStarredMessages;

  /// No description provided for @messageAdmin.
  ///
  /// In en, this message translates to:
  /// **'Message Admin'**
  String get messageAdmin;

  /// No description provided for @noStudentMessages.
  ///
  /// In en, this message translates to:
  /// **'No student messages yet.'**
  String get noStudentMessages;

  /// No description provided for @conversationsHere.
  ///
  /// In en, this message translates to:
  /// **'Your conversations will appear here.'**
  String get conversationsHere;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotificationsYet;

  /// No description provided for @viewCourse.
  ///
  /// In en, this message translates to:
  /// **'View course'**
  String get viewCourse;

  /// No description provided for @enrolledOn.
  ///
  /// In en, this message translates to:
  /// **'Enrolled on'**
  String get enrolledOn;

  /// No description provided for @agenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get agenda;

  /// No description provided for @noEventsForDay.
  ///
  /// In en, this message translates to:
  /// **'No events for this day.'**
  String get noEventsForDay;

  /// No description provided for @eventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get eventDeleted;

  /// No description provided for @failedToDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete event'**
  String get failedToDeleteEvent;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get setReminder;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventTitle;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder title'**
  String get reminderTitle;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @setDuration.
  ///
  /// In en, this message translates to:
  /// **'Set duration'**
  String get setDuration;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @reminderSetOnMoodle.
  ///
  /// In en, this message translates to:
  /// **'Reminder set on Moodle'**
  String get reminderSetOnMoodle;

  /// No description provided for @eventCreatedOnMoodle.
  ///
  /// In en, this message translates to:
  /// **'Event created on Moodle'**
  String get eventCreatedOnMoodle;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @chooseImageFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose image from device'**
  String get chooseImageFromDevice;

  /// No description provided for @profileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated!'**
  String get profileImageUpdated;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @couldNotPickImage.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image from device.'**
  String get couldNotPickImage;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @looksGood.
  ///
  /// In en, this message translates to:
  /// **'Looks good!'**
  String get looksGood;

  /// No description provided for @signInToViewGrades.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your grades'**
  String get signInToViewGrades;

  /// No description provided for @noGradesYet.
  ///
  /// In en, this message translates to:
  /// **'No grades yet'**
  String get noGradesYet;

  /// No description provided for @enrollInCoursesForGrades.
  ///
  /// In en, this message translates to:
  /// **'Enroll in courses to see your grades here.'**
  String get enrollInCoursesForGrades;

  /// No description provided for @failedToLoadGrades.
  ///
  /// In en, this message translates to:
  /// **'Failed to load grades'**
  String get failedToLoadGrades;

  /// No description provided for @noGradeRecorded.
  ///
  /// In en, this message translates to:
  /// **'No grade recorded yet'**
  String get noGradeRecorded;

  /// No description provided for @loginRequiredToDownload.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequiredToDownload;

  /// No description provided for @pleaseLoginToDownload.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view course downloads.'**
  String get pleaseLoginToDownload;

  /// No description provided for @noFilesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No files available'**
  String get noFilesAvailable;

  /// No description provided for @documentsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Documents uploaded to your courses\nwill appear here.'**
  String get documentsWillAppearHere;

  /// No description provided for @failedToLoadDownloads.
  ///
  /// In en, this message translates to:
  /// **'Failed to load downloads'**
  String get failedToLoadDownloads;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file'**
  String get couldNotOpenFile;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @noEnrolledCoursesYet.
  ///
  /// In en, this message translates to:
  /// **'No enrolled courses yet'**
  String get noEnrolledCoursesYet;

  /// No description provided for @exploreAndEnrollCourses.
  ///
  /// In en, this message translates to:
  /// **'Explore and enroll in courses to start learning'**
  String get exploreAndEnrollCourses;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements:'**
  String get passwordRequirements;

  /// No description provided for @changePasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordBtn;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @newPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get newPasswordsDontMatch;

  /// No description provided for @passwordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get passwordMustBeDifferent;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @differentFromCurrent.
  ///
  /// In en, this message translates to:
  /// **'Different from current password'**
  String get differentFromCurrent;

  /// No description provided for @enrollNow.
  ///
  /// In en, this message translates to:
  /// **'Enroll Now'**
  String get enrollNow;

  /// No description provided for @enrolled2.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrolled2;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price Breakdown'**
  String get priceBreakdown;

  /// No description provided for @courseDetails.
  ///
  /// In en, this message translates to:
  /// **'Course Details'**
  String get courseDetails;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @lessonCount.
  ///
  /// In en, this message translates to:
  /// **'lessons'**
  String get lessonCount;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable'**
  String get videoUnavailable;

  /// No description provided for @openVideo.
  ///
  /// In en, this message translates to:
  /// **'Open Video'**
  String get openVideo;

  /// No description provided for @showLessons.
  ///
  /// In en, this message translates to:
  /// **'Show lessons'**
  String get showLessons;

  /// No description provided for @hideLessons.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideLessons;

  /// No description provided for @lessonsShownBelow.
  ///
  /// In en, this message translates to:
  /// **'Lessons are shown below the player. Scroll inside the lessons panel to browse.'**
  String get lessonsShownBelow;

  /// No description provided for @lessonsHidden.
  ///
  /// In en, this message translates to:
  /// **'Lessons are hidden. Use Show lessons to choose a video.'**
  String get lessonsHidden;

  /// No description provided for @enrolledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Enrolled successfully! 🎉'**
  String get enrolledSuccessfully;

  /// No description provided for @failedToEnroll.
  ///
  /// In en, this message translates to:
  /// **'Failed to enroll'**
  String get failedToEnroll;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String available(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
