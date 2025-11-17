// lib/features/consumer/presentation/pages/complaints_page.dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';

class ComplaintsPage extends StatefulWidget {
  final ConsumerRepository repository;

  const ComplaintsPage({super.key, required this.repository});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late Future<List<Complaint>> _future;
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _orderIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getComplaints();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: _orderIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Order ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Complaint Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Complaint Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  final id = int.tryParse(_orderIdCtrl.text.trim());
                  if (id == null) return;
                  await widget.repository.createComplaint(
                    id,
                    _titleCtrl.text.trim(),
                    _descriptionCtrl.text.trim(),
                  );
                  _orderIdCtrl.clear();
                  _titleCtrl.clear();
                  _descriptionCtrl.clear();
                  if (!mounted) return;
                  await _refresh();
                },
                child: Text(l10n.complaints),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Complaint>>(
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
                    final c = list[i];
                    return ListTile(
                      title: Text(c.title),
                      subtitle: Text('Status: ${c.status}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
