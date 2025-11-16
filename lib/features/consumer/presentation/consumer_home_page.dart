// lib/features/consumer/presentation/consumer_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/routing/app_router.dart' show BuildContextX;
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/entities/user.dart';
import '../data/consumer_repository.dart';
import 'pages/catalog_page.dart';
import 'pages/orders_page.dart';
import 'pages/links_page.dart';
import 'pages/complaints_page.dart';
import 'pages/profile_page.dart';

class ConsumerHomePage extends StatefulWidget {
  final User user;

  const ConsumerHomePage({super.key, required this.user});

  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      CatalogPage(repository: context.read<ConsumerRepository>()),
      OrdersPage(repository: context.read<ConsumerRepository>()),
      LinksPage(repository: context.read<ConsumerRepository>()),
      ComplaintsPage(repository: context.read<ConsumerRepository>()),
      ProfilePage(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.consumerApp}'),
        actions: [
          PrimaryButton(
            label: l10n.logout,
            onPressed: () async {
              await context.read<AuthRepository>().logout();
              if (!mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.store), label: l10n.catalog),
          NavigationDestination(icon: const Icon(Icons.list_alt), label: l10n.orders),
          NavigationDestination(icon: const Icon(Icons.link), label: l10n.links),
          NavigationDestination(icon: const Icon(Icons.report_problem), label: l10n.complaints),
          NavigationDestination(icon: const Icon(Icons.person), label: l10n.profile),
        ],
      ),
    );
  }
}
