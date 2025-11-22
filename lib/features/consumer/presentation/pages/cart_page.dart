// lib/features/consumer/presentation/pages/cart_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';
import '../../domain/entities/cart_item.dart';
import '../cart_provider.dart';

class CartPage extends StatefulWidget {
  final ConsumerRepository repository;
  final VoidCallback? onNavigateToCatalog;

  const CartPage({
    super.key,
    required this.repository,
    this.onNavigateToCatalog,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<ConsumerOrder>> _pastOrdersFuture;
  late Future<Map<String, String>> _supplierNamesMap;
  String _orderFilter = 'all'; // Default to 'all'
  final Map<int, bool> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _pastOrdersFuture = widget.repository.getOrders();
    _supplierNamesMap = _loadSupplierNames();
  }

  Future<Map<String, String>> _loadSupplierNames() async {
    final suppliers = await widget.repository.getAllSuppliers();
    final map = <String, String>{};
    for (final supplier in suppliers) {
      map[supplier.code] = supplier.name;
    }
    return map;
  }

  Future<void> _refreshPastOrders() async {
    setState(() {
      _pastOrdersFuture = widget.repository.getOrders();
    });
  }

  Future<void> _handlePlaceOrder(
    CartProvider cartProvider,
    String deliveryMethod,
    DateTime deliveryDate,
    String deliveryAddress, {
    String? notes,
  }) async {
    if (cartProvider.items.isEmpty) return;

    // Group items by supplier - create one order per supplier
    final grouped = _groupItemsBySupplier(cartProvider.items);
    
    for (final entry in grouped.entries) {
      final items = entry.value;
      
      if (items.isEmpty) continue;
      
      // Get supplier ID from first item
      final supplierId = items.first.supplierId;
      
      try {
        await widget.repository.createOrder(
          items,
          supplierId,
          deliveryMethod,
          deliveryDate,
          deliveryAddress,
          notes: notes,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
        return; // Stop if one order fails
      }
    }

    cartProvider.clear();
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.orderPlaced),
        backgroundColor: Colors.green[700],
      ),
    );

    await _refreshPastOrders();
  }

  Future<void> _handleClearCart(CartProvider cartProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearCart),
        content: Text(context.l10n.areYouSureClearCart),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.clearCart),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cartProvider.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cartCleared),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  Future<void> _handleReorder(ConsumerOrder order, CartProvider cartProvider) async {
    // Check if consumer is still linked to the supplier
    if (order.supplierCode != null) {
      final isLinked = await widget.repository.isLinkedToSupplier(order.supplierCode!);
      if (!isLinked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are no longer linked to this supplier. Cannot reorder.'),
            backgroundColor: Colors.orange[700],
          ),
        );
        return;
      }
    }
    
    // Fetch actual order items from repository
    try {
      final orderItems = await widget.repository.getOrderItems(order.id);
      
      // Get supplier info for the order
      final supplierCode = order.supplierCode ?? order.supplierId?.toString() ?? '';
      final supplierId = order.supplierId ?? 0;
      
      // Get product names and details
      for (final item in orderItems) {
        final productName = await widget.repository.getProductName(item.productId);
        
        // Get product details to get price, unit, etc.
        final catalog = await widget.repository.getCatalog();
        final product = catalog.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
            id: item.productId,
            name: productName,
            unit: 'piece',
            price: item.unitPrice,
            category: '',
          ),
        );
        
        // Create cart item with actual product data
        final cartItem = CartItem(
          productId: item.productId,
          productName: product.name,
          supplierId: supplierId,
          supplierCode: supplierCode,
          price: product.price,
          discountPrice: null, // Use current price, not order price
          currency: order.currency,
          unit: product.unit,
          imageUrl: product.imageUrl,
          quantity: item.quantity.toInt(),
        );
        
        cartProvider.addItem(cartItem);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${orderItems.length} ${context.l10n.items} added to cart'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reordering: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _showComplaintModal(BuildContext context, ConsumerOrder order) async {
    if (order.supplierId == null || order.supplierCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.supplierInfoMissing),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComplaintModal(
        order: order,
        repository: widget.repository,
        onComplaintSent: () {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.complaintSent),
                backgroundColor: Colors.green[700],
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showOrderPlacementModal(
    BuildContext context,
    CartProvider cartProvider,
    List<CartItem> cartItems,
  ) async {
    if (cartItems.isEmpty) return;

    // Get supplier info for delivery options
    final supplierCodes = cartItems.map((item) => item.supplierCode).toSet().toList();
    final supplierInfoMap = <String, Supplier>{};
    
    for (final code in supplierCodes) {
      // Get supplier info - in real app, fetch from repository
      // For now, we'll use mock data
      try {
        final products = await widget.repository.getProductsBySupplier(code);
        if (products.isNotEmpty) {
          final supplier = await widget.repository.getSupplierDetailsForProduct(
            products.first.productId,
            code,
          );
          if (supplier != null) {
            supplierInfoMap[code] = supplier;
          }
        }
      } catch (e) {
        // Handle error
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderPlacementModal(
        cartItems: cartItems,
        supplierInfoMap: supplierInfoMap,
        repository: widget.repository,
        onConfirm: (deliveryMethod, deliveryDate, address, note) async {
          await _handlePlaceOrder(
            cartProvider,
            deliveryMethod,
            deliveryDate,
            address,
            notes: note,
          );
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Map<String, List<CartItem>> _groupItemsBySupplier(List<CartItem> items) {
    final grouped = <String, List<CartItem>>{};
    for (final item in items) {
      if (!grouped.containsKey(item.supplierCode)) {
        grouped[item.supplierCode] = [];
      }
      grouped[item.supplierCode]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartItems = cartProvider.items;
        final hasItems = cartItems.isNotEmpty;
        final total = cartProvider.totalPrice;
        final currency = cartItems.isNotEmpty ? cartItems.first.currency : 'KZT';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cart Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart Title
                    Text(
                      l10n.cart,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (hasItems) ...[
                      // Group items by supplier
                      FutureBuilder<Map<String, String>>(
                        future: _supplierNamesMap,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final supplierNames = snapshot.data ?? {};
                          return Column(
                            children: _buildSupplierGroups(
                              context,
                              theme,
                              cartItems,
                              cartProvider,
                              supplierNames,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Total Sum
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.totalSum,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${total.toStringAsFixed(0)} $currency',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Place Order Button
                      FilledButton(
                        onPressed: () => _showOrderPlacementModal(context, cartProvider, cartItems),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(l10n.placeOrder),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _handleClearCart(cartProvider),
                        child: Text(l10n.clearCart),
                      ),
                    ] else ...[
                      // Empty cart state
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.green[300],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.cartEmpty,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.browseCatalogToAddProducts,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (widget.onNavigateToCatalog != null)
                                FilledButton.icon(
                                  onPressed: widget.onNavigateToCatalog,
                                  icon: const Icon(Icons.store),
                                  label: Text(l10n.browseCatalog),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Previous Orders Section (always shown)
              _buildPreviousOrdersSection(context, theme, l10n, cartProvider),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSupplierGroups(
    BuildContext context,
    ThemeData theme,
    List<CartItem> cartItems,
    CartProvider cartProvider,
    Map<String, String> supplierNames,
  ) {
    final grouped = _groupItemsBySupplier(cartItems);
    final widgets = <Widget>[];

    grouped.forEach((supplierCode, items) {
      // Supplier name header - left aligned
      final supplierName = supplierNames[supplierCode] ?? supplierCode;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 0, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              supplierName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ),
      );

      // Products for this supplier
      for (final item in items) {
        widgets.add(
          _buildCartItemCard(context, theme, item, cartProvider),
        );
      }

      // Add spacing between supplier groups
      if (supplierCode != grouped.keys.last) {
        widgets.add(const SizedBox(height: 16));
      }
    });

    return widgets;
  }

  Widget _buildCartItemCard(
    BuildContext context,
    ThemeData theme,
    CartItem item,
    CartProvider cartProvider,
  ) {
    final effectivePrice = item.discountPrice ?? item.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image,
                              color: Colors.green[300],
                              size: 40,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.image,
                          color: Colors.green[300],
                          size: 40,
                        ),
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Price and quantity under product name (no crossed-out price)
                      Row(
                        children: [
                          Text(
                            '${effectivePrice.toStringAsFixed(0)} ${item.currency}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '× ${item.quantity}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Quantity selector (without line total on the right)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              cartProvider.updateQuantity(
                                item.productId,
                                item.supplierCode,
                                item.quantity - 1,
                              );
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.green[700],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              cartProvider.updateQuantity(
                                item.productId,
                                item.supplierCode,
                                item.quantity + 1,
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.green[700],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousOrdersSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    CartProvider cartProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Previous Orders Title
          Text(
            l10n.previousOrders,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(theme, l10n.allCategories, 'all', l10n),
                const SizedBox(width: 8),
                _buildFilterChip(theme, l10n.pending, 'pending', l10n),
                const SizedBox(width: 8),
                _buildFilterChip(theme, l10n.inProcess, 'in_process', l10n),
                const SizedBox(width: 8),
                _buildFilterChip(theme, l10n.completed, 'completed', l10n),
                const SizedBox(width: 8),
                _buildFilterChip(theme, l10n.rejected, 'rejected', l10n),
                const SizedBox(width: 8),
                _buildFilterChip(theme, 'Canceled', 'canceled', l10n),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<ConsumerOrder>>(
            future: _pastOrdersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      l10n.noPreviousOrders,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }

              final allOrders = snapshot.data!;
              final filteredOrders = _filterOrders(allOrders);
              
              if (filteredOrders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      l10n.noPreviousOrders,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ...filteredOrders.map((order) => _buildPastOrderCard(context, theme, l10n, order, cartProvider)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme, String label, String value, AppLocalizations l10n) {
    final isSelected = _orderFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          // If clicking the same selected tab, select "all" (like catalog page)
          if (isSelected) {
            _orderFilter = 'all';
          } else {
            _orderFilter = value;
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

  List<ConsumerOrder> _filterOrders(List<ConsumerOrder> orders) {
    if (_orderFilter == 'all') return orders;
    
    return orders.where((order) {
      // Database enum values: pending, accepted, rejected, in_progress, completed, cancelled
      final status = order.status.toLowerCase().replaceAll(' ', '_');
      switch (_orderFilter) {
        case 'pending':
          return status == 'pending';
        case 'in_process':
          return status == 'in_progress' || status == 'accepted'; // accepted is also in progress
        case 'completed':
          return status == 'completed';
        case 'rejected':
          return status == 'rejected';
        case 'canceled':
          return status == 'cancelled'; // Database uses 'cancelled' (double l)
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildPastOrderCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConsumerOrder order,
    CartProvider cartProvider,
  ) {
    final statusColor = _getStatusColor(order.status);
    final isExpanded = _expandedOrders[order.id] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedOrders[order.id] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatDate(order.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} ${l10n.items} · ${order.total.toStringAsFixed(0)} ${order.currency}',
                style: theme.textTheme.bodyMedium,
              ),
              // Expanded order details
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                // Mock order items - in real app, fetch from repository
                _buildOrderDetails(context, theme, l10n, order),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showComplaintModal(context, order),
                    icon: const Icon(Icons.report_problem, size: 18),
                    label: Text(l10n.complain),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[700]!),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _handleReorder(order, cartProvider),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reorder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConsumerOrder order,
  ) {
    // Check if consumer is still linked to the supplier
    return FutureBuilder<bool>(
      future: order.supplierCode != null 
          ? widget.repository.isLinkedToSupplier(order.supplierCode!)
          : Future.value(false),
      builder: (context, linkSnapshot) {
        // If not linked, show unlinked message
        if (linkSnapshot.hasData && !linkSnapshot.data! && order.supplierCode != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You are no longer linked to this supplier. Order details are not available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Fetch actual order items from repository
        return FutureBuilder<List<OrderItem>>(
          future: widget.repository.getOrderItems(order.id),
          builder: (context, snapshot) {
            final items = snapshot.hasData ? snapshot.data! : order.items;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Supplier info if available
            if (order.supplierCode != null || order.supplierId != null) ...[
              FutureBuilder<Map<String, String>>(
                future: _supplierNamesMap,
                builder: (context, supplierSnapshot) {
                  if (supplierSnapshot.hasData && order.supplierCode != null) {
                    final supplierName = supplierSnapshot.data![order.supplierCode] ?? order.supplierCode ?? 'Supplier';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.store, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            supplierName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            Text(
              l10n.orderDetails,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'No items in this order',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _getProductName(item.productId),
                        builder: (context, productSnapshot) {
                          final productName = productSnapshot.hasData 
                              ? productSnapshot.data! 
                              : 'Product #${item.productId}';
                          return Text(
                            '$productName × ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}',
                            style: theme.textTheme.bodyMedium,
                          );
                        },
                      ),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)} ${order.currency}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalSum,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.total.toStringAsFixed(0)} ${order.currency}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            // Cancel / reject reason (if any)
            const SizedBox(height: 8),
            // Database enum values: pending, accepted, rejected, in_progress, completed, cancelled
            if ((order.status.toLowerCase() == 'cancelled' || // Database uses 'cancelled' (double l)
                    order.status.toLowerCase() == 'rejected') &&
                order.notes != null &&
                order.notes!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancel reason',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.red[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
          },
        );
      },
    );
  }

  Future<String> _getProductName(int productId) async {
    try {
      final catalog = await widget.repository.getCatalog();
      final product = catalog.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(
          id: productId,
          name: 'Product #$productId',
          unit: 'pcs',
          price: 0,
          category: '',
        ),
      );
      return product.name;
    } catch (e) {
      return 'Product #$productId';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'accepted':
        return Colors.green;
      case 'in progress':
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Order Placement Modal
class _OrderPlacementModal extends StatefulWidget {
  final List<CartItem> cartItems;
  final Map<String, Supplier> supplierInfoMap;
  final ConsumerRepository repository;
  final Future<void> Function(String deliveryMethod, DateTime deliveryDate, String address, String? note) onConfirm;

  const _OrderPlacementModal({
    required this.cartItems,
    required this.supplierInfoMap,
    required this.repository,
    required this.onConfirm,
  });

  @override
  State<_OrderPlacementModal> createState() => _OrderPlacementModalState();
}

class _OrderPlacementModalState extends State<_OrderPlacementModal> {
  String? _selectedDeliveryMethod;
  DateTime? _selectedDate;
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final Map<String, List<String>> _availableMethods = {};

  @override
  void initState() {
    super.initState();
    _initializeDeliveryMethods();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _addressController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  void _initializeDeliveryMethods() {
    final grouped = <String, List<CartItem>>{};
    for (final item in widget.cartItems) {
      if (!grouped.containsKey(item.supplierCode)) {
        grouped[item.supplierCode] = [];
      }
      grouped[item.supplierCode]!.add(item);
    }

    final methods = <String>{};
    for (final entry in grouped.entries) {
      final supplier = widget.supplierInfoMap[entry.key];
      if (supplier != null) {
        if (supplier.deliveryAvailability) methods.add('delivery');
        if (supplier.pickupAvailability) methods.add('pickup');
      }
    }

    _availableMethods['all'] = methods.toList();
    if (_availableMethods['all']!.isNotEmpty) {
      _selectedDeliveryMethod = _availableMethods['all']!.first;
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_updateButtonState);
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.orderDetails,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Delivery Method
              Text(
                l10n.deliveryMethod,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...(_availableMethods['all'] ?? []).map((method) {
                final isDelivery = method == 'delivery';
                return RadioListTile<String>(
                  title: Text(isDelivery ? l10n.delivery : l10n.pickup),
                  value: method,
                  groupValue: _selectedDeliveryMethod,
                  onChanged: (value) {
                    setState(() => _selectedDeliveryMethod = value);
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 24),
              // Delivery Date
              Text(
                l10n.deliveryDate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : l10n.deliveryDate,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Address
              Text(
                l10n.address,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: l10n.address,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // Note (optional)
              Text(
                '${l10n.note} ${l10n.optional}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: l10n.note,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              // Confirm Button
              FilledButton(
                onPressed: _selectedDeliveryMethod != null &&
                        _selectedDate != null &&
                        _addressController.text.isNotEmpty
                    ? () async {
                        await widget.onConfirm(
                          _selectedDeliveryMethod!,
                          _selectedDate!,
                          _addressController.text,
                          _noteController.text.isEmpty ? null : _noteController.text,
                        );
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.confirmOrder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Complaint Modal
class _ComplaintModal extends StatefulWidget {
  final ConsumerOrder order;
  final ConsumerRepository repository;
  final VoidCallback onComplaintSent;

  const _ComplaintModal({
    required this.order,
    required this.repository,
    required this.onComplaintSent,
  });

  @override
  State<_ComplaintModal> createState() => _ComplaintModalState();
}

class _ComplaintModalState extends State<_ComplaintModal> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedImagePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in title and description'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.repository.createComplaint(
        widget.order.id,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        imageUrl: _selectedImagePath,
        supplierId: widget.order.supplierId,
        supplierCode: widget.order.supplierCode,
      );
      
      if (mounted) {
        widget.onComplaintSent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending complaint: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickImage() async {
    // In a real app, use image_picker package
    // For now, just simulate image selection
    setState(() {
      _selectedImagePath = 'path/to/image.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.placeComplaint,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${widget.order.id}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.complaintTitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.complaintDescription,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              // Photo upload
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.uploadPhoto),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              if (_selectedImagePath != null) ...[
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey[600]),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() => _selectedImagePath = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Submit button
              FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.placeComplaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
