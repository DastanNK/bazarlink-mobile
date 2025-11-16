// lib/features/shell/presentation/role_based_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_router.dart' show BuildContextX;
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/entities/user.dart';
import '../../auth/domain/value_objects.dart';
import '../../consumer/presentation/consumer_home_page.dart';
import '../../sales/presentation/sales_home_page.dart';

class RoleBasedHomePage extends StatelessWidget {
  const RoleBasedHomePage({super.key});

  Future<User?> _loadUser(BuildContext context) {
    final repo = context.read<AuthRepository>();
    return repo.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<User?>(
      future: _loadUser(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // не залогинен → на логин
          Future.microtask(
            () => Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRouter.login, (_) => false),
          );
          return const SizedBox.shrink();
        }

        // Consumer → ConsumerHomePage
        if (user.role == UserRole.consumer) {
          return ConsumerHomePage(user: user);
        }

        // SalesRep → SalesHomePage
        if (user.role == UserRole.salesRepresentative) {
          return SalesHomePage(user: user);
        }

        // Остальные роли: пока просто текст
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
          ),
          body: Center(
            child: Text(
              'Role ${user.role} UI is not implemented yet.\n'
              'Try consumer@test.com or sales@test.com.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
