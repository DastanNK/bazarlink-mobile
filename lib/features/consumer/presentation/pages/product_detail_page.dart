// lib/features/consumer/presentation/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';
import '../../domain/entities/cart_item.dart';
import '../cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final ConsumerRepository repository;
  final String supplierCode;
  final VoidCallback? onNavigateToCart;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.repository,
    required this.supplierCode,
    this.onNavigateToCart,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Supplier? _supplier;
  bool _isLoading = true;
  bool _isLinked = false;
  bool _isCheckingLink = true;
  int _quantity = 1;
  bool _showStepper = false;

  @override
  void initState() {
    super.initState();
    _loadSupplierDetails();
  }

  Future<void> _loadSupplierDetails() async {
    setState(() {
      _isLoading = true;
    });

    final supplier = await widget.repository.getSupplierDetailsForProduct(
      widget.product.id,
      widget.supplierCode,
    );
    
    setState(() {
      _supplier = supplier;
      _isLoading = false;
    });

    if (supplier != null) {
      await _checkLinkStatus();
    }
  }

  Future<void> _checkLinkStatus() async {
    if (_supplier == null) {
      setState(() {
        _isCheckingLink = false;
      });
      return;
    }

    final linked = await widget.repository.isLinkedToSupplier(_supplier!.code);
    
    // Check if product is already in cart
    final cartProvider = context.read<CartProvider>();
    final cartItems = cartProvider.items.where(
      (item) => item.productId == widget.product.id && item.supplierCode == _supplier!.code,
    ).toList();
    
    setState(() {
      _isLinked = linked;
      _isCheckingLink = false;
      // Restore quantity and stepper state from cart
      if (cartItems.isNotEmpty && cartItems.first.quantity > 0) {
        _quantity = cartItems.first.quantity;
        _showStepper = true; // Always show stepper if item is in cart
      }
    });
  }

  Future<void> _handleRequestLink() async {
    if (_supplier == null) return;
    
    await widget.repository.requestLink(_supplier!.code);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.linkRequested),
        backgroundColor: Colors.green[700],
      ),
    );
    
    await _checkLinkStatus();
  }

  Future<void> _handleOrder() async {
    if (_supplier == null || !_isLinked) return;

    final cartProvider = context.read<CartProvider>();
    final cartItem = CartItem(
      productId: widget.product.id,
      productName: widget.product.name,
      supplierId: _supplier!.id,
      supplierCode: _supplier!.code,
      price: _supplier!.price,
      discountPrice: _supplier!.discountPrice,
      currency: _supplier!.currency,
      unit: _supplier!.unit,
      imageUrl: widget.product.imageUrl,
      quantity: _quantity,
    );
    
    cartProvider.addItem(cartItem);
    
    setState(() {
      _showStepper = true;
    });
  }

  void _incrementQuantity() {
    if (_supplier == null || !_isLinked) return;
    setState(() {
      _quantity++;
    });
    _updateCartQuantity();
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
        _updateCartQuantity();
      } else {
        // If quantity is 1 and we try to decrease, remove from cart and hide stepper
        _quantity = 1;
        _showStepper = false;
        _removeFromCart();
      }
    });
  }

  void _updateCartQuantity() {
    if (_supplier == null || !_isLinked) return;
    final cartProvider = context.read<CartProvider>();
    cartProvider.updateQuantity(
      widget.product.id,
      _supplier!.code,
      _quantity,
    );
  }

  void _removeFromCart() {
    if (_supplier == null) return;
    final cartProvider = context.read<CartProvider>();
    cartProvider.removeItem(widget.product.id, _supplier!.code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        elevation: 0,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _supplier == null
              ? Center(
                  child: Text(
                    'Supplier information not available',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Product Image
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green[100]!,
                              Colors.green[50]!,
                            ],
                          ),
                        ),
                        child: widget.product.imageUrl != null
                            ? Image.network(
                                widget.product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholderImage(theme),
                              )
                            : _buildPlaceholderImage(theme),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              widget.product.name,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.product.category,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.green[900],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Supplier Information Card
                            if (_isCheckingLink)
                              const Center(child: CircularProgressIndicator())
                            else if (!_isLinked)
                              // Request Link Button
                              FilledButton.icon(
                                onPressed: _handleRequestLink,
                                icon: const Icon(Icons.link),
                                label: Text(l10n.requestLink),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              )
                            else ...[
                              // Supplier Details Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Supplier Name
                                    Row(
                                      children: [
                                        Icon(Icons.store, color: Colors.green[700], size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          _supplier!.name,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    if (_supplier!.description != null) ...[
                                      Text(
                                        l10n.description,
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _supplier!.description!,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    
                                    // Price Section
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.price,
                                                style: theme.textTheme.labelSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  if (_supplier!.discountPrice != null) ...[
                                                    Text(
                                                      '${_supplier!.price.toStringAsFixed(0)} ${_supplier!.currency}',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        decoration: TextDecoration.lineThrough,
                                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${_supplier!.discountPrice!.toStringAsFixed(0)} ${_supplier!.currency}',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        color: Colors.green[700],
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ] else
                                                    Text(
                                                      '${_supplier!.price.toStringAsFixed(0)} ${_supplier!.currency}',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        color: Colors.green[700],
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_supplier!.discountPrice != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${((1 - _supplier!.discountPrice! / _supplier!.price) * 100).toStringAsFixed(0)}% OFF',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: Colors.green[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Stock and Min Order
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInfoChip(
                                            theme,
                                            Icons.inventory_2,
                                            '${l10n.stock}: ${_supplier!.stockQuantity} ${_supplier!.unit}',
                                            _supplier!.stockQuantity > 0
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildInfoChip(
                                            theme,
                                            Icons.shopping_cart,
                                            '${l10n.minOrder}: ${_supplier!.minOrderQuantity} ${_supplier!.unit}',
                                            Colors.green[700]!,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Delivery Options
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildAvailabilityChip(
                                          theme,
                                          Icons.local_shipping,
                                          l10n.delivery,
                                          _supplier!.deliveryAvailability,
                                        ),
                                        _buildAvailabilityChip(
                                          theme,
                                          Icons.store,
                                          l10n.pickup,
                                          _supplier!.pickupAvailability,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Lead Time
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${l10n.leadTime}: ${_supplier!.leadTimeDays} ${l10n.days}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Order Button or Quantity Stepper
                              if (!_showStepper)
                                FilledButton.icon(
                                  onPressed: _handleOrder,
                                  icon: const Icon(Icons.shopping_cart),
                                  label: Text(l10n.addToCart),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Quantity',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: _decrementQuantity,
                                                icon: const Icon(Icons.remove_circle_outline),
                                                color: Colors.green[700],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$_quantity',
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[900],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: _incrementQuantity,
                                                icon: const Icon(Icons.add_circle_outline),
                                                color: Colors.green[700],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: () {
                                        // Use callback if provided, otherwise just pop
                                        if (widget.onNavigateToCart != null) {
                                          Navigator.of(context).pop();
                                          widget.onNavigateToCart!();
                                        } else {
                                          // Just pop back - user can navigate to cart manually
                                          Navigator.of(context).pop();
                                        }
                                      },
                                      icon: const Icon(Icons.shopping_cart),
                                      label: Text(l10n.goToCart),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        minimumSize: const Size(double.infinity, 50),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlaceholderImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image,
          size: 80,
          color: Colors.green[300],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip(ThemeData theme, IconData icon, String label, bool available) {
    final color = available ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
