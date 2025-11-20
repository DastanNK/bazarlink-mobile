// lib/features/sales/presentation/pages/sales_consumers_page.dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
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

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getLinkedConsumers();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'blocked':
      case 'removed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleAcceptLink(SalesConsumer consumer) async {
    try {
      await widget.repository.acceptLink(consumer.linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.linkAccepted}: ${consumer.name}'),
          backgroundColor: Colors.green[700],
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.error}: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _handleRejectLink(SalesConsumer consumer) async {
    try {
      await widget.repository.rejectLink(consumer.linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.reject}: ${consumer.name}'),
          backgroundColor: Colors.orange[700],
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.error}: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _handleAssignLink(SalesConsumer consumer) async {
    try {
      await widget.repository.assignLink(consumer.linkId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.linkAssigned}: ${consumer.name}'),
          backgroundColor: Colors.green[700],
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.error}: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return FutureBuilder<List<SalesConsumer>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noLinkedConsumers,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        final list = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final c = list[i];
              final isPending = c.status == 'pending';
              final isAccepted = c.status == 'accepted';
              final isAssigned = c.assignedSalesRepId != null;
              final statusColor = _getStatusColor(c.status);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.green[700],
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (c.city != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        c.city!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              c.status.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Action buttons
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleAcceptLink(c),
                                icon: const Icon(Icons.check),
                                label: Text(l10n.accept),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleRejectLink(c),
                                icon: const Icon(Icons.close),
                                label: Text(l10n.reject),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isAccepted && !isAssigned) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAssignLink(c),
                            icon: const Icon(Icons.person_add),
                            label: Text(l10n.assign),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ] else if (isAssigned) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              l10n.assigned,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
