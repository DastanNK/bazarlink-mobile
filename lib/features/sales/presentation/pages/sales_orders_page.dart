// lib/features/sales/presentation/pages/sales_orders_page.dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
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
  String _statusFilter = 'all'; // all, pending, in_progress, completed, rejected, cancelled

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

  List<SalesOrder> _filterOrders(List<SalesOrder> orders) {
    if (_statusFilter == 'all') return orders;
    
    return orders.where((order) {
      final status = order.status.toLowerCase().replaceAll(' ', '_');
      switch (_statusFilter) {
        case 'pending':
          return status == 'pending';
        case 'in_progress':
          return status == 'in_progress' || status == 'inprogress' || status == 'accepted';
        case 'completed':
          return status == 'completed';
        case 'rejected':
          return status == 'rejected';
        case 'cancelled':
        case 'canceled':
          return status == 'cancelled' || status == 'canceled';
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _handleAcceptOrder(SalesOrder order) async {
    try {
      await widget.repository.acceptOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.orderAccepted}: ${order.orderNumber ?? 'Order #${order.id}'}'),
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

  Future<void> _handleRejectOrder(SalesOrder order) async {
    try {
      await widget.repository.rejectOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.orderRejected}: ${order.orderNumber ?? 'Order #${order.id}'}'),
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

  Future<void> _handleCancelOrder(SalesOrder order) async {
    final l10n = context.l10n;
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for canceling this order'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter cancel reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reason is required')),
                );
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await widget.repository.cancelOrder(order.id, reason: result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Canceled: ${order.orderNumber ?? 'Order #${order.id}'}'),
            backgroundColor: Colors.orange[700],
          ),
        );
        _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _handleCompleteOrder(SalesOrder order) async {
    final l10n = context.l10n;
    try {
      await widget.repository.completeOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order Completed: ${order.orderNumber ?? 'Order #${order.id}'}'),
          backgroundColor: Colors.green[700],
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase().replaceAll(' ', '_');
    switch (normalizedStatus) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in_progress':
      case 'inprogress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'canceled':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return FutureBuilder<List<SalesOrder>>(
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
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noOrders,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        final list = snapshot.data!;
        final filteredList = _filterOrders(list);
        return Column(
          children: [
            // Filter tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(theme, l10n.allCategories, 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n.pending, 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n.inProcess, 'in_progress'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n.completed, 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, l10n.rejected, 'rejected'),
                    const SizedBox(width: 8),
                    _buildFilterChip(theme, 'Cancelled', 'cancelled'),
                  ],
                ),
              ),
            ),
            // Orders list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'No orders found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (_, i) {
                          final o = filteredList[i];
              final isPending = o.status == 'pending' || o.status == 'Pending';
              final statusColor = _getStatusColor(o.status);
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
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              color: Colors.green[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.orderNumber ?? 'Order #${o.id}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  o.consumerName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
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
                              o.status,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${o.total.toStringAsFixed(0)} ${o.currency}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleAcceptOrder(o),
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
                                onPressed: () => _handleRejectOrder(o),
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
                      ] else if (o.status == 'in_progress' || o.status == 'in progress' || o.status == 'accepted') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleCancelOrder(o),
                                icon: const Icon(Icons.cancel),
                                label: Text(l10n.cancel),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleCompleteOrder(o),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
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
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(ThemeData theme, String labelText, String value) {
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
