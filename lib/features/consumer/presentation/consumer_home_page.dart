// lib/features/consumer/presentation/consumer_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/routing/app_router.dart' show BuildContextX;
import '../../auth/domain/entities/user.dart';
import '../data/consumer_repository.dart';
import 'pages/cart_page.dart';
import 'pages/catalog_page.dart';
import 'pages/chats_page.dart';
import 'pages/links_page.dart';
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
    final repository = context.read<ConsumerRepository>();
    final pages = [
      CartPage(
        repository: repository,
        onNavigateToCatalog: () => setState(() => _index = 1),
      ),
      CatalogPage(
        repository: repository,
        onNavigateToCart: () => setState(() => _index = 0),
      ),
      LinksPage(repository: repository),
      ChatsPage(repository: repository),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.consumerApp}'),
        actions: [
          // Language dropdown
          Consumer<LocalizationProvider>(
            builder: (context, langProvider, _) {
              return PopupMenuButton<AppLanguage>(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, color: Colors.green[700], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        langProvider.language.displayName,
                        style: TextStyle(color: Colors.green[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                onSelected: (language) {
                  langProvider.setLanguage(language);
                },
                itemBuilder: (context) => AppLanguage.values.map((lang) {
                  return PopupMenuItem<AppLanguage>(
                    value: lang,
                    child: Row(
                      children: [
                        if (langProvider.language == lang)
                          Icon(Icons.check, size: 18, color: Colors.green[700])
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(lang.displayName),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          // Profile icon
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfilePage(user: widget.user),
                ),
              );
            },
            tooltip: l10n.profile,
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.shopping_cart), label: l10n.cart),
          NavigationDestination(icon: const Icon(Icons.store), label: l10n.catalog),
          NavigationDestination(icon: const Icon(Icons.link), label: l10n.links),
          NavigationDestination(icon: const Icon(Icons.chat), label: l10n.chats),
        ],
      ),
    );
  }
}
