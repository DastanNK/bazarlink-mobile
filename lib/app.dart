// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/localization_provider.dart';
import 'core/routing/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_repository_mock.dart';
import 'features/consumer/data/consumer_repository.dart';
import 'features/consumer/data/consumer_repository_mock.dart';
import 'features/consumer/presentation/cart_provider.dart';
import 'features/sales/data/sales_repository.dart';
import 'features/sales/data/sales_repository_mock.dart';

class SCPApp extends StatelessWidget {
  const SCPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        Provider<AuthRepository>(create: (_) => MockAuthRepository()),
        Provider<ConsumerRepository>(create: (_) => MockConsumerRepository()),
        Provider<SalesRepository>(create: (_) => MockSalesRepository()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'SCP',
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.green,
            ),
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.languageSelection,
          );
        },
      ),
    );
  }
}
