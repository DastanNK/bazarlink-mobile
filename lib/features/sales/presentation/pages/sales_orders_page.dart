// lib/features/sales/presentation/pages/sales_orders_page.dart
import 'package:flutter/material.dart';

import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';

class SalesOrdersPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesOrdersPage({super.key, required this.repository});

  @override
  State<SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends State<SalesOrdersPage> {
  late Future<List<SalesOrder>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalesOrder>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final o = list[i];
              final isPending = o.status == 'pending';
              return ListTile(
                title: Text('Order #${o.id} • ${o.consumerName}'),
                subtitle: Text('Status: ${o.status}'),
                trailing: isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await widget.repository.acceptOrder(o.id);
                              if (!mounted) return;
                              await _refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await widget.repository.rejectOrder(o.id);
                              if (!mounted) return;
                              await _refresh();
                            },
                          ),
                        ],
                      )
                    : Text('${o.total.toStringAsFixed(0)} ₸'),
              );
            },
          ),
        );
      },
    );
  }
}
