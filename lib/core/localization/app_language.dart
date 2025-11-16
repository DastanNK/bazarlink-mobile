enum AppLanguage { kk, ru, en }

extension AppLanguageExt on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.kk:
        return 'kk';
      case AppLanguage.ru:
        return 'ru';
      case AppLanguage.en:
        return 'en';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.kk:
        return 'Қазақ';
      case AppLanguage.ru:
        return 'Русский';
      case AppLanguage.en:
        return 'English';
    }
  }
}
