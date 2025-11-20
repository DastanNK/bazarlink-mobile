// lib/features/consumer/presentation/pages/orders_page.dart
import 'package:flutter/material.dart';

import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';

class OrdersPage extends StatefulWidget {
  final ConsumerRepository repository;

  const OrdersPage({super.key, required this.repository});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<ConsumerOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getOrders();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<ConsumerOrder>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final o = orders[i];
            return ListTile(
              title: Text('Order #${o.id}'),
              subtitle: Text(
                '${o.status} • ${o.createdAt.toLocal()}',
              ),
              trailing: Text('${o.total.toStringAsFixed(0)} ₸'),
            );
          },
        );
      },
    );
  }
}
