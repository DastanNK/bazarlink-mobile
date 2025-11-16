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

  String get search => _t(kk: 'Іздеу', ru: 'Поиск', en: 'Search');
  String get allCategories => _t(kk: 'Барлығы', ru: 'Все', en: 'All');
  String get vegetables => _t(kk: 'Көкөністер', ru: 'Овощи', en: 'Vegetables');
  String get fruits => _t(kk: 'Жемістер', ru: 'Фрукты', en: 'Fruits');
  String get meat => _t(kk: 'Ет', ru: 'Мясо', en: 'Meat');
  String get dairy => _t(kk: 'Сүт өнімдері', ru: 'Молочные продукты', en: 'Dairy');
  String get order => _t(kk: 'Тапсырыс', ru: 'Заказ', en: 'Order');
  String get addToCart => _t(kk: 'Себетке қосу', ru: 'В корзину', en: 'Add to Cart');
  String get description => _t(kk: 'Сипаттама', ru: 'Описание', en: 'Description');
  String get price => _t(kk: 'Баға', ru: 'Цена', en: 'Price');
  String get stock => _t(kk: 'Қор', ru: 'Наличие', en: 'Stock');
  String get minOrder => _t(kk: 'Минималды тапсырыс', ru: 'Минимальный заказ', en: 'Min Order');
  String get delivery => _t(kk: 'Жеткізу', ru: 'Доставка', en: 'Delivery');
  String get pickup => _t(kk: 'Алу', ru: 'Самовывоз', en: 'Pickup');
  String get leadTime => _t(kk: 'Жеткізу мерзімі', ru: 'Срок доставки', en: 'Lead Time');
  String get days => _t(kk: 'күн', ru: 'дней', en: 'days');
  String get requestLink => _t(kk: 'Байланыс сұрау', ru: 'Запросить связь', en: 'Request Link');
  String get available => _t(kk: 'Қолжетімді', ru: 'Доступно', en: 'Available');
  String get notAvailable => _t(kk: 'Қолжетімсіз', ru: 'Недоступно', en: 'Not Available');
  String get orderCreated => _t(kk: 'Тапсырыс жасалды', ru: 'Заказ создан', en: 'Order Created');
  String get linkRequested => _t(kk: 'Байланыс сұралды', ru: 'Связь запрошена', en: 'Link Requested');
  String get linkSupplier => _t(kk: 'Жеткізушіге байланыс', ru: 'Связаться с поставщиком', en: 'Link Supplier');
  String get suppliers => _t(kk: 'Жеткізушілер', ru: 'Поставщики', en: 'Suppliers');
  String get goToCart => _t(kk: 'Себетке өту', ru: 'Перейти в корзину', en: 'Go to Cart');
  String get seeCart => _t(kk: 'Себетті көру', ru: 'Посмотреть корзину', en: 'See Cart');
  String get cartTotal => _t(kk: 'Жалпы сома', ru: 'Общая сумма', en: 'Total');

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
