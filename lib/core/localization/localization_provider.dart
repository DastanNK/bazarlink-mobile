// lib/core/localization/localization_provider.dart
import 'package:flutter/material.dart';
import 'app_language.dart';

class LocalizationProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.ru;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage language) {
    if (language != _language) {
      _language = language;
      notifyListeners();
    }
  }
}
