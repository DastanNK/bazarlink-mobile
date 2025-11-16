// lib/features/sales/presentation/pages/sales_complaints_page.dart
import 'package:flutter/material.dart';

import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';

class SalesComplaintsPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesComplaintsPage({super.key, required this.repository});

  @override
  State<SalesComplaintsPage> createState() => _SalesComplaintsPageState();
}

class _SalesComplaintsPageState extends State<SalesComplaintsPage> {
  late Future<List<SalesComplaint>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalesComplaint>>(
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
              leading: const Icon(Icons.report_problem),
              title: Text(c.title),
              subtitle: Text('${c.consumerName} • ${c.status}'),
            );
          },
        );
      },
    );
  }
}
