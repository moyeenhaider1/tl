import 'package:flutter/foundation.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  final List<String> _supportedLanguages = [
    'en', // English
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'ja', // Japanese
    'zh', // Chinese
  ];

  String get currentLanguage => _currentLanguage;
  List<String> get supportedLanguages => [..._supportedLanguages];

  void setLanguage(String languageCode) {
    if (_supportedLanguages.contains(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Spanish';
      case 'fr': return 'French';
      case 'de': return 'German';
      case 'it': return 'Italian';
      case 'ja': return 'Japanese';
      case 'zh': return 'Chinese';
      default: return 'Unknown';
    }
  }
}