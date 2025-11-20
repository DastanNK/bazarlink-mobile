// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/localization_provider.dart';
import '../../features/auth/presentation/consumer_sign_up_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/settings/presentation/language_selection_page.dart';
import '../../features/shell/presentation/role_based_home_page.dart';

class AppRouter {
  static const languageSelection = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case languageSelection:
        return MaterialPageRoute(
          builder: (_) => const LanguageSelectionPage(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
      case signup:
        return MaterialPageRoute(
          builder: (_) => const ConsumerSignUpPage(),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const RoleBasedHomePage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Unknown route')),
          ),
        );
    }
  }
}

extension BuildContextX on BuildContext {
  AppLocalizations get l10n {
    final lang = this.read<LocalizationProvider>().language;
    return AppLocalizations.of(lang);
  }
}
