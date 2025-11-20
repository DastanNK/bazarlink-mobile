// lib/features/sales/presentation/sales_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/localization_provider.dart';
import '../../../core/routing/app_router.dart' show BuildContextX;
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/entities/user.dart';
import '../../consumer/presentation/cart_provider.dart';
import '../data/sales_repository.dart';
import 'pages/sales_consumers_page.dart';
import 'pages/sales_complaints_page.dart';
import 'pages/sales_chat_page.dart';
import 'pages/sales_orders_page.dart';
import 'pages/sales_profile_page.dart';

class SalesHomePage extends StatefulWidget {
  final User user;

  const SalesHomePage({super.key, required this.user});

  @override
  State<SalesHomePage> createState() => _SalesHomePageState();
}

class _SalesHomePageState extends State<SalesHomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.read<SalesRepository>();

    final pages = [
      SalesConsumersPage(repository: repo),
      SalesOrdersPage(repository: repo),
      SalesComplaintsPage(repository: repo),
      SalesChatPage(repository: repo),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesRepApp),
        actions: [
          // Profile icon
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SalesProfilePage(user: widget.user),
                ),
              );
            },
            tooltip: l10n.profile,
          ),
          PrimaryButton(
            label: l10n.logout,
            onPressed: () async {
              // Clear cart before logout (if exists)
              try {
                context.read<CartProvider>().clear();
              } catch (e) {
                // CartProvider might not be available for sales rep, ignore
              }
              await context.read<AuthRepository>().logout();
              if (!mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: Consumer<LocalizationProvider>(
        builder: (context, langProvider, _) {
          final l10n = context.l10n;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.people), label: l10n.consumers),
              NavigationDestination(icon: const Icon(Icons.shopping_cart), label: l10n.orders),
              NavigationDestination(icon: const Icon(Icons.report_problem), label: l10n.complaints),
              NavigationDestination(icon: const Icon(Icons.chat), label: l10n.chat),
            ],
          );
        },
      ),
    );
  }
}
