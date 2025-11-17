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
  String get cart => _t(kk: 'Себет', ru: 'Корзина', en: 'Cart');
  String get chats => _t(kk: 'Чаттар', ru: 'Чаты', en: 'Chats');
  String get currentOrder => _t(kk: 'Ағымдағы тапсырыс', ru: 'Текущий заказ', en: 'Current Order');
  String get pastOrders => _t(kk: 'Алдыңғы тапсырыстар', ru: 'Прошлые заказы', en: 'Past Orders');
  String get previousOrders => _t(kk: 'Алдыңғы тапсырыстар', ru: 'Предыдущие заказы', en: 'Previous Orders');
  String get noPreviousOrders => _t(kk: 'Сізде алдыңғы тапсырыстар жоқ', ru: 'У вас нет предыдущих заказов', en: 'You have no previous orders');
  String get subtotal => _t(kk: 'Аралық сома', ru: 'Промежуточная сумма', en: 'Subtotal');
  String get totalSum => _t(kk: 'Жалпы сома', ru: 'Общая сумма', en: 'Total Sum');
  String get estimatedDelivery => _t(kk: 'Жеткізу мерзімі', ru: 'Срок доставки', en: 'Estimated Delivery');
  String get placeOrder => _t(kk: 'Тапсырыс беру', ru: 'Оформить заказ', en: 'Place Order');
  String get clearCart => _t(kk: 'Себетті тазалау', ru: 'Очистить корзину', en: 'Clear Cart');
  String get reorder => _t(kk: 'Қайта тапсырыс беру', ru: 'Повторить заказ', en: 'Reorder');
  String get orderHistory => _t(kk: 'Тапсырыс тарихы', ru: 'История заказов', en: 'Order History');
  String get cartEmpty => _t(kk: 'Сіздің себетіңіз бос', ru: 'Ваша корзина пуста', en: 'Your cart is empty');
  String get browseCatalog => _t(kk: 'Каталогты ашу', ru: 'Открыть каталог', en: 'Open Catalog');
  String get noOrdersYet => _t(kk: 'Тапсырыстар жоқ', ru: 'Заказов пока нет', en: 'No orders yet');
  String get firstOrder => _t(kk: 'Бірінші тапсырысты беріңіз', ru: 'Сделайте первый заказ', en: 'Place your first order');
  String get items => _t(kk: 'заттар', ru: 'товаров', en: 'items');
  String get item => _t(kk: 'зат', ru: 'товар', en: 'item');
  String get minimumOrder => _t(kk: 'Минималды тапсырыс сомасы', ru: 'Минимальная сумма заказа', en: 'Minimum Order Amount');
  String get someItemsUnavailable => _t(kk: 'Кейбір заттар қолжетімсіз', ru: 'Некоторые товары недоступны', en: 'Some items are no longer available');
  String get itemsAddedFromOrder => _t(kk: 'Тапсырыстан заттар қосылды', ru: 'Товары из заказа добавлены', en: 'Items added from previous order');
  String get orderPlaced => _t(kk: 'Тапсырыс берілді', ru: 'Заказ оформлен', en: 'Order Placed');
  String get cartCleared => _t(kk: 'Себет тазаланды', ru: 'Корзина очищена', en: 'Cart Cleared');
  String get supplier => _t(kk: 'Жеткізуші', ru: 'Поставщик', en: 'Supplier');
  String get mySuppliers => _t(kk: 'Менің жеткізушілерім', ru: 'Мои поставщики', en: 'My Suppliers');
  String get allSuppliers => _t(kk: 'Барлық жеткізушілер', ru: 'Все поставщики', en: 'All Suppliers');
  String get suggestedSuppliers => _t(kk: 'Ұсынылған жеткізушілер', ru: 'Рекомендуемые поставщики', en: 'Suggested Suppliers');
  String get searchSuppliers => _t(kk: 'Жеткізушілерді іздеу', ru: 'Поиск поставщиков', en: 'Search suppliers by name');
  String get linked => _t(kk: 'Байланысқан', ru: 'Связан', en: 'Linked');
  String get pending => _t(kk: 'Күтуде', ru: 'В ожидании', en: 'Pending');
  String get notLinked => _t(kk: 'Байланыспаған', ru: 'Не связан', en: 'Not Linked');
  String get blocked => _t(kk: 'Бұғатталған', ru: 'Заблокирован', en: 'Blocked');
  String get openCatalog => _t(kk: 'Каталогты ашу', ru: 'Открыть каталог', en: 'Open Catalog');
  String get requestSent => _t(kk: 'Сұрау жіберілді', ru: 'Запрос отправлен', en: 'Request sent');
  String get cancelRequest => _t(kk: 'Сұрауды жою', ru: 'Отменить запрос', en: 'Cancel Request');
  String get requestLinkToSupplier => _t(kk: 'Жеткізушіге байланыс сұрау', ru: 'Запросить связь с поставщиком', en: 'Request link to supplier');
  String get introduceBusiness => _t(kk: 'Бизнесіңізді таныстырыңыз (міндетті емес)', ru: 'Представьте свой бизнес (необязательно)', en: 'Introduce your business (optional)');
  String get businessExample => _t(kk: 'Мысал: "Алматыдағы жаңа кафе, апталық жеткізулерді іздеп жатырмыз."', ru: 'Пример: "Мы новое кафе в Алматы, ищем еженедельные поставки."', en: 'Example: "We are a new cafe in Almaty looking for weekly deliveries."');
  String get sendRequest => _t(kk: 'Сұрау жіберу', ru: 'Отправить запрос', en: 'Send Request');
  String get noLinkedSuppliers => _t(kk: 'Сізде байланысқан жеткізушілер жоқ', ru: 'У вас нет связанных поставщиков', en: 'You don\'t have any linked suppliers');
  String get sendLinkRequestToStart => _t(kk: 'Тапсырыс беруді бастау үшін байланыс сұрауын жіберіңіз', ru: 'Отправьте запрос на связь, чтобы начать заказывать', en: 'Send a link request to start ordering');
  String get browseSuppliers => _t(kk: 'Жеткізушілерді көру', ru: 'Просмотреть поставщиков', en: 'Browse Suppliers');
  String get linksInfoBanner => _t(kk: 'Бұл жалпыға ашық базар емес. Жеткізушілердің каталогтарына қол жеткізу үшін оларға байланыс сұрауын жіберіңіз.', ru: 'Это не публичный маркетплейс. Отправьте запрос на связь поставщикам, чтобы получить доступ к их каталогам.', en: 'This is not a public marketplace. Send a link request to suppliers to access their catalogs.');
  String get city => _t(kk: 'Қала', ru: 'Город', en: 'City');
  String get deliveryMethod => _t(kk: 'Жеткізу әдісі', ru: 'Способ доставки', en: 'Delivery Method');
  String get deliveryDate => _t(kk: 'Жеткізу күні', ru: 'Дата доставки', en: 'Delivery Date');
  String get address => _t(kk: 'Мекен-жай', ru: 'Адрес', en: 'Address');
  String get note => _t(kk: 'Ескерту', ru: 'Примечание', en: 'Note');
  String get optional => _t(kk: '(міндетті емес)', ru: '(необязательно)', en: '(optional)');
  String get confirmOrder => _t(kk: 'Тапсырысты растау', ru: 'Подтвердить заказ', en: 'Confirm Order');
  String get inProcess => _t(kk: 'Орындалуда', ru: 'В процессе', en: 'In Process');
  String get completed => _t(kk: 'Аяқталған', ru: 'Завершен', en: 'Completed');
  String get rejected => _t(kk: 'Қабылданбады', ru: 'Отклонен', en: 'Rejected');
  String get orderDetails => _t(kk: 'Тапсырыс мәліметтері', ru: 'Детали заказа', en: 'Order Details');
  String get category => _t(kk: 'Категория', ru: 'Категория', en: 'Category');
  String get businessDetails => _t(kk: 'Бизнес мәліметтері', ru: 'Детали бизнеса', en: 'Business Details');
  String get description => _t(kk: 'Сипаттама', ru: 'Описание', en: 'Description');
  String get deliveryRegions => _t(kk: 'Жеткізу аймақтары', ru: 'Регионы доставки', en: 'Delivery Regions');
  String get paymentTerms => _t(kk: 'Төлем шарттары', ru: 'Условия оплаты', en: 'Payment Terms');
  String get deliverySchedule => _t(kk: 'Жеткізу кестесі', ru: 'График доставки', en: 'Delivery Schedule');
  String get contactInfo => _t(kk: 'Байланыс ақпараты', ru: 'Контактная информация', en: 'Contact Information');
  String get phone => _t(kk: 'Телефон', ru: 'Телефон', en: 'Phone');
  String get email => _t(kk: 'Email', ru: 'Email', en: 'Email');
  String get website => _t(kk: 'Веб-сайт', ru: 'Веб-сайт', en: 'Website');
  String get workingHours => _t(kk: 'Жұмыс уақыты', ru: 'Часы работы', en: 'Working Hours');
  String get productCategories => _t(kk: 'Өнім категориялары', ru: 'Категории товаров', en: 'Product Categories');
  String get noLinkedSuppliersMessage => _t(kk: 'Сізде байланысқан жеткізушілер жоқ. Жеткізушіні басып, мәліметтерді көру және байланыс сұрауын жіберу.', ru: 'У вас нет связанных поставщиков. Нажмите на поставщика, чтобы просмотреть детали и отправить запрос на связь.', en: 'You don\'t have any linked suppliers. Tap a supplier to view details and send a link request.');
  String get complain => _t(kk: 'Шағымдану', ru: 'Пожаловаться', en: 'Complain');
  String get placeComplaint => _t(kk: 'Шағым жіберу', ru: 'Отправить жалобу', en: 'Place Complaint');
  String get complaintTitle => _t(kk: 'Тақырып', ru: 'Заголовок', en: 'Title');
  String get complaintDescription => _t(kk: 'Сипаттама', ru: 'Описание', en: 'Description');
  String get uploadPhoto => _t(kk: 'Фото жүктеу', ru: 'Загрузить фото', en: 'Upload Photo');
  String get complaintSent => _t(kk: 'Сіздің шағымдарыңыз жіберілді. Оны әрі қарай Чаттар бетінде көре аласыз.', ru: 'Ваша жалоба отправлена. Вы можете просмотреть её далее на странице Чаты.', en: 'Your complaint was sent. You can view it further in the Chats page.');
  String get typeMessage => _t(kk: 'Хабарлама теріңіз...', ru: 'Введите сообщение...', en: 'Type message...');
  String get send => _t(kk: 'Жіберу', ru: 'Отправить', en: 'Send');

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
