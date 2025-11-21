// lib/features/sales/presentation/pages/sales_consumers_page.dart
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
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
  String _statusFilter = 'all'; // all, pending, accepted, blocked

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
      case 'rejected':
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

  Future<void> _handleCancelLink(SalesConsumer consumer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Link'),
        content: const Text('Are you sure you want to cancel this link? This will unlink the customer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Link'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.cancelLink(consumer.linkId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link Canceled: ${consumer.name}'),
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
  }

  Future<void> _handleBlockConsumer(SalesConsumer consumer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Consumer'),
        content: const Text('Are you sure you want to block this consumer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.blockConsumer(consumer.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consumer Blocked: ${consumer.name}'),
            backgroundColor: Colors.red[700],
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
  }

  List<SalesConsumer> _filterConsumers(List<SalesConsumer> consumers) {
    if (_statusFilter == 'all') return consumers;
    
    return consumers.where((consumer) {
      final status = consumer.status.toLowerCase();
      switch (_statusFilter) {
        case 'pending':
          return status == 'pending';
        case 'accepted':
          return status == 'accepted';
        case 'removed':
          return status == 'removed' || status == 'rejected'; // Support both for backward compatibility
        case 'rejected':
          return status == 'rejected' || status == 'removed'; // Support both for backward compatibility
        case 'blocked':
          return status == 'blocked';
        default:
          return true;
      }
    }).toList();
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
        final filteredList = _filterConsumers(list);
        
        return Column(
          children: [
            // Filter tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(theme, l10n, l10n.allCategories, 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n, l10n.pending, 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n, 'Accepted', 'accepted'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n, 'Rejected', 'removed'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n, 'Blocked', 'blocked'),
                  ],
                ),
              ),
            ),
            // Consumers list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: filteredList.isEmpty
                    ? Center(
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
                              'No consumers found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (_, i) {
                          final c = filteredList[i];
                          final isPending = c.status == 'pending';
                          final isAccepted = c.status == 'accepted';
                          final isRejected = c.status == 'removed' || c.status == 'rejected';
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
                      // Request message if pending
                      if (isPending && c.requestMessage != null && c.requestMessage!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.message, size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Request Message:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.requestMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      ] else if (isRejected) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleAcceptLink(c),
                                icon: const Icon(Icons.check),
                                label: Text('Reaccept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _handleBlockConsumer(c),
                              icon: const Icon(Icons.block),
                              color: Colors.red[700],
                              tooltip: 'Block',
                            ),
                          ],
                        ),
                      ] else if (isAccepted) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!isAssigned)
                              Expanded(
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
                            if (!isAssigned) const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleCancelLink(c),
                                icon: const Icon(Icons.cancel),
                                label: Text(l10n.cancel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[700],
                                  side: BorderSide(color: Colors.orange[700]!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _handleBlockConsumer(c),
                              icon: const Icon(Icons.block),
                              color: Colors.red[700],
                              tooltip: 'Block',
                            ),
                          ],
                        ),
                        if (isAssigned) ...[
                          const SizedBox(height: 8),
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
                      // Block button for all statuses
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _handleBlockConsumer(c),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('Block'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
    );
      },
    );
  }

  Widget _buildFilterChip(ThemeData theme, AppLocalizations l10n, String labelText, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(labelText),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isSelected) {
            _statusFilter = 'all';
          } else {
            _statusFilter = value;
          }
        });
      },
      selectedColor: Colors.green[100],
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[900] : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
