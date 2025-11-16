// lib/features/sales/presentation/pages/sales_consumers_page.dart
import 'package:flutter/material.dart';

import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';

class SalesConsumersPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesConsumersPage({super.key, required this.repository});

  @override
  State<SalesConsumersPage> createState() => _SalesConsumersPageState();
}

class _SalesConsumersPageState extends State<SalesConsumersPage> {
  late Future<List<SalesConsumer>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getLinkedConsumers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalesConsumer>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data!;
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final c = list[i];
            return ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(c.name),
              subtitle: Text('Status: ${c.status}'),
            );
          },
        );
      },
    );
  }
}
