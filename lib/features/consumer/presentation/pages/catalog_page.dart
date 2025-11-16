// lib/features/consumer/presentation/pages/catalog_page.dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';

class CatalogPage extends StatefulWidget {
  final ConsumerRepository repository;

  const CatalogPage({super.key, required this.repository});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<List<Product>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) {
            final p = products[index];
            return ListTile(
              title: Text(p.name),
              subtitle: Text('${p.price.toStringAsFixed(0)} / ${p.unit}'),
              trailing: FilledButton(
                onPressed: () async {
                  await widget.repository.createOrder(p);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order created for ${p.name}')),
                  );
                },
                child: Text(l10n.orders),
              ),
            );
          },
        );
      },
    );
  }
}
