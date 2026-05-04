import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  String _language = 'English';
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _courseUpdates = true;
  bool _newLessons = true;
  bool _assignments = true;
  bool _grades = true;
  bool _announcements = true;
  bool _messages = true;

  String get language => _language;
  bool get pushNotifications => _pushNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get courseUpdates => _courseUpdates;
  bool get newLessons => _newLessons;
  bool get assignments => _assignments;
  bool get grades => _grades;
  bool get announcements => _announcements;
  bool get messages => _messages;

  /// Maps language name to a Flutter Locale.
  Locale get locale {
    switch (_language) {
      case 'Hindi':
        return const Locale('hi');
      default:
        return const Locale('en');
    }
  }

  static const List<String> supportedLanguages = ['English', 'Hindi'];

  PreferencesProvider() {
    _load();
  }

  Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('pref_language') ?? 'English';
    _pushNotifications = prefs.getBool('pref_push') ?? true;
    _emailNotifications = prefs.getBool('pref_email') ?? true;
    _courseUpdates = prefs.getBool('pref_courseUpdates') ?? true;
    _newLessons = prefs.getBool('pref_newLessons') ?? true;
    _assignments = prefs.getBool('pref_assignments') ?? true;
    _grades = prefs.getBool('pref_grades') ?? true;
    _announcements = prefs.getBool('pref_announcements') ?? true;
    _messages = prefs.getBool('pref_messages') ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', lang);
  }

  Future<void> setNotification(String key, bool value) async {
    switch (key) {
      case 'push':          _pushNotifications = value; break;
      case 'email':         _emailNotifications = value; break;
      case 'courseUpdates': _courseUpdates = value; break;
      case 'newLessons':    _newLessons = value; break;
      case 'assignments':   _assignments = value; break;
      case 'grades':        _grades = value; break;
      case 'announcements': _announcements = value; break;
      case 'messages':      _messages = value; break;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_$key', value);
  }
}
