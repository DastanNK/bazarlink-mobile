// lib/features/consumer/presentation/pages/links_page.dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';

class LinksPage extends StatefulWidget {
  final ConsumerRepository repository;

  const LinksPage({super.key, required this.repository});

  @override
  State<LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<LinksPage> {
  late Future<List<LinkInfo>> _future;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getLinks();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Supplier code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await widget.repository.requestLink(_codeCtrl.text.trim());
                  _codeCtrl.clear();
                  if (!mounted) return;
                  await _refresh();
                },
                child: const Text('Request'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<LinkInfo>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final links = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  itemCount: links.length,
                  itemBuilder: (_, i) {
                    final link = links[i];
                    return ListTile(
                      title: Text(link.supplierName),
                      subtitle: Text('Status: ${link.status}'),
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
