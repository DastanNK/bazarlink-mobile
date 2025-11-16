// lib/core/localization/app_localizations.dart
import 'app_language.dart';

class AppLocalizations {
  final AppLanguage language;

  AppLocalizations(this.language);

  static AppLocalizations of(AppLanguage language) => AppLocalizations(language);

  String get appTitle => _t(
        kk: 'SCP платформасы',
        ru: 'SCP платформа',
        en: 'SCP Platform',
      );

  String get login => _t(kk: 'Кіру', ru: 'Вход', en: 'Login');
  String get email => _t(kk: 'Email', ru: 'Email', en: 'Email');
  String get password => _t(kk: 'Құпия сөз', ru: 'Пароль', en: 'Password');
  String get logout => _t(kk: 'Шығу', ru: 'Выход', en: 'Logout');

  String get chooseLanguage =>
      _t(kk: 'Тілді таңдаңыз', ru: 'Выберите язык', en: 'Choose language');

  String get consumerApp =>
      _t(kk: 'Тұтынушы', ru: 'Покупатель', en: 'Consumer');

  String get salesRepApp =>
      _t(kk: 'Сатушы өкілі', ru: 'Sales Representative', en: 'Sales Representative');

  String get catalog => _t(kk: 'Каталог', ru: 'Каталог', en: 'Catalog');
  String get orders => _t(kk: 'Тапсырыстар', ru: 'Заказы', en: 'Orders');
  String get links => _t(kk: 'Байланыстар', ru: 'Связи', en: 'Links');
  String get complaints =>
      _t(kk: 'Шағымдар', ru: 'Жалобы', en: 'Complaints');
  String get incidents =>
      _t(kk: 'Инциденты', ru: 'Инциденты', en: 'Incidents');
  String get profile => _t(kk: 'Профиль', ru: 'Профиль', en: 'Profile');
  String get chat => _t(kk: 'Чат', ru: 'Чат', en: 'Chat');

  String _t({required String kk, required String ru, required String en}) {
    switch (language) {
      case AppLanguage.kk:
        return kk;
      case AppLanguage.ru:
        return ru;
      case AppLanguage.en:
        return en;
    }
  }
}
