// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/localization_provider.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_repository_api.dart';
import 'features/consumer/data/consumer_repository.dart';
import 'features/consumer/data/consumer_repository_api.dart';
import 'features/consumer/presentation/cart_provider.dart';
import 'features/sales/data/sales_repository.dart';
import 'features/sales/data/sales_repository_api.dart';

class SCPApp extends StatelessWidget {
  const SCPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // API Client
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),
        // Auth Repository
        Provider<AuthRepository>(
          create: (ctx) => ApiAuthRepository(
            ctx.read<ApiClient>(),
          ),
        ),
        // Consumer Repository
        Provider<ConsumerRepository>(
          create: (ctx) => ApiConsumerRepository(
            ctx.read<ApiClient>(),
            ctx.read<AuthRepository>(),
          ),
        ),
        // Sales Repository
        Provider<SalesRepository>(
          create: (ctx) => ApiSalesRepository(
            ctx.read<ApiClient>(),
            ctx.read<AuthRepository>(),
          ),
        ),
      ],
      child: Consumer<LocalizationProvider>(
        builder: (context, langProvider, _) {
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
