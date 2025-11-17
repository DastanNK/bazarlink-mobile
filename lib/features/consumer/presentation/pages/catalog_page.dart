// lib/features/consumer/presentation/pages/catalog_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';
import '../cart_provider.dart';
import 'product_detail_page.dart';
import 'links_page.dart';

class CatalogPage extends StatefulWidget {
  final ConsumerRepository repository;

  const CatalogPage({super.key, required this.repository});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late Future<List<LinkInfo>> _linkedSuppliersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSupplierCode; // null means "All" is selected
  List<String> _categories = [];
  String? _selectedCategory;
  List<SupplierProduct> _allProducts = []; // All products from all suppliers
  List<SupplierProduct> _filteredProducts = []; // Products after supplier/category filter
  bool _isLoadingAllProducts = true;
  bool _isLoadingCategories = false;
  bool _isLoadingFilteredProducts = false;

  @override
  void initState() {
    super.initState();
    _linkedSuppliersFuture = widget.repository.getLinkedSuppliers();
    _loadAllProducts();
    _searchController.addListener(() {
      final newQuery = _searchController.text.toLowerCase();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
        });
        _handleSearchChange();
      }
    });
  }

  Future<void> _handleSearchChange() async {
    // When searching, hide category selection and reload products
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _selectedCategory = null;
      });
      
      if (_selectedSupplierCode != null) {
        // Load all products from selected supplier (no category filter)
        await _loadFilteredProducts(_selectedSupplierCode!);
      }
      // If "All" is selected, _filteredProducts is already _allProducts
    } else {
      // When search is cleared, restore category selection if supplier is selected
      if (_selectedSupplierCode != null && _categories.isNotEmpty) {
        setState(() {
          _selectedCategory = _categories.first;
        });
        await _loadFilteredProducts(_selectedSupplierCode!, category: _categories.first);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoadingAllProducts = true;
    });

    final suppliers = await widget.repository.getLinkedSuppliers();
    final allProducts = <SupplierProduct>[];

    for (final supplier in suppliers) {
      final supplierCode = supplier.supplierCode ?? 
                          supplier.supplierName.substring(0, 3).toUpperCase();
      final products = await widget.repository.getProductsBySupplier(supplierCode);
      allProducts.addAll(products);
    }

    setState(() {
      _allProducts = allProducts;
      _filteredProducts = allProducts;
      _isLoadingAllProducts = false;
    });
  }

  Future<void> _handleSupplierSelection(String? supplierCode, String? supplierName) async {
    // Toggle: if clicking the same supplier, unselect it (go back to "All")
    if (_selectedSupplierCode == supplierCode) {
      setState(() {
        _selectedSupplierCode = null;
        _selectedCategory = null;
        _categories = [];
        _filteredProducts = _allProducts;
      });
      return;
    }

    // Select new supplier
    setState(() {
      _selectedSupplierCode = supplierCode;
      _selectedCategory = null;
      _isLoadingCategories = true;
      _isLoadingFilteredProducts = true;
    });

    if (supplierCode == null) {
      // "All" selected
      setState(() {
        _categories = [];
        _filteredProducts = _allProducts;
        _isLoadingCategories = false;
        _isLoadingFilteredProducts = false;
      });
      return;
    }

    // Load categories for this supplier
    final categories = await widget.repository.getCategoriesForSupplier(supplierCode);
    
    // Only select first category if not searching
    final firstCategory = _searchQuery.isEmpty && categories.isNotEmpty ? categories.first : null;
    
    setState(() {
      _categories = categories;
      _selectedCategory = firstCategory;
      _isLoadingCategories = false;
    });

    // Load products for this supplier and category (only if not searching)
    if (_searchQuery.isEmpty) {
      await _loadFilteredProducts(supplierCode, category: firstCategory);
    } else {
      // If searching, load all products from this supplier (no category filter)
      await _loadFilteredProducts(supplierCode);
    }
  }

  Future<void> _handleCategorySelection(String category) async {
    if (_selectedSupplierCode == null) return;

    setState(() {
      _selectedCategory = category;
      _isLoadingFilteredProducts = true;
    });

    // Only filter by category if not searching
    if (_searchQuery.isEmpty) {
      await _loadFilteredProducts(_selectedSupplierCode!, category: category);
    } else {
      // If searching, load all products from supplier (search will filter them)
      await _loadFilteredProducts(_selectedSupplierCode!);
    }
  }

  Future<void> _loadFilteredProducts(String supplierCode, {String? category}) async {
    final products = await widget.repository.getProductsBySupplier(
      supplierCode,
      category: category,
    );
    
    setState(() {
      _filteredProducts = products;
      _isLoadingFilteredProducts = false;
    });
  }

  List<SupplierProduct> get _displayProducts {
    var products = _filteredProducts;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) => 
        p.productName.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    return products;
  }

  void _navigateToProductDetail(SupplierProduct supplierProduct) {
    final product = Product(
      id: supplierProduct.productId,
      name: supplierProduct.productName,
      unit: supplierProduct.unit,
      price: supplierProduct.price,
      category: supplierProduct.category,
      imageUrl: supplierProduct.imageUrl,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          repository: widget.repository,
          supplierCode: supplierProduct.supplierCode,
        ),
      ),
    );
  }

  void _navigateToLinksPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LinksPage(repository: widget.repository),
      ),
    );
  }

  String _getCategoryLocalized(String category, BuildContext context) {
    final l10n = context.l10n;
    switch (category) {
      case 'Vegetables':
        return l10n.vegetables;
      case 'Fruits':
        return l10n.fruits;
      case 'Meat':
        return l10n.meat;
      case 'Dairy':
        return l10n.dairy;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final hasCartItems = cartProvider.itemCount > 0;
        final cartTotal = cartProvider.totalPrice;
        final firstItem = cartProvider.items.isNotEmpty ? cartProvider.items.first : null;
        final currency = firstItem?.currency ?? 'KZT';

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: theme.colorScheme.onSurface),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Cart Summary Bar
            if (hasCartItems)
              InkWell(
                onTap: () {
                  // Navigate to cart/orders page
                  // For now, just show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.seeCart} - ${cartProvider.itemCount} items'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.green[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.cartTotal}: ${cartTotal.toStringAsFixed(0)} $currency',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward, color: Colors.green[700]),
                    ],
                  ),
                ),
              ),

            // Supplier List
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FutureBuilder<List<LinkInfo>>(
            future: _linkedSuppliersFuture,
      builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                      onPressed: _navigateToLinksPage,
                      icon: const Icon(Icons.link),
                      label: Text(l10n.linkSupplier),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                );
              }

              final suppliers = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suppliers.length + 1, // +1 for "All" tab
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" tab
                    final isSelected = _selectedSupplierCode == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(l10n.allCategories),
                        selected: isSelected,
                        onSelected: (_) => _handleSupplierSelection(null, null),
                        selectedColor: Colors.green[100],
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.green[900] : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.green[700]! : theme.colorScheme.outline.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }

                  final supplier = suppliers[index - 1];
                  final supplierCode = supplier.supplierCode ?? 
                                      supplier.supplierName.substring(0, 3).toUpperCase();
                  final isSelected = _selectedSupplierCode == supplierCode;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(supplier.supplierName),
                      selected: isSelected,
                      onSelected: (_) => _handleSupplierSelection(supplierCode, supplier.supplierName),
                      selectedColor: Colors.green[100],
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.green[900] : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.green[700]! : theme.colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Category Section (only shown when a specific supplier is selected and not searching)
        if (_selectedSupplierCode != null && _searchQuery.isEmpty) ...[
          if (_isLoadingCategories)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else if (_categories.isNotEmpty)
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(_getCategoryLocalized(category, context)),
                      selected: isSelected,
                      onSelected: (_) => _handleCategorySelection(category),
                      selectedColor: Colors.green[100],
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.green[900] : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.green[700]! : theme.colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
              ),
            );
          },
              ),
            ),
        ],

        // Product List
        Expanded(
          child: _isLoadingAllProducts
              ? const Center(child: CircularProgressIndicator())
              : _isLoadingFilteredProducts
                  ? const Center(child: CircularProgressIndicator())
                  : _displayProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _displayProducts.length,
                          itemBuilder: (context, index) {
                            final product = _displayProducts[index];
                            return _buildProductCard(context, theme, product);
                          },
                        ),
        ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ThemeData theme, SupplierProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green[100]!,
                      Colors.green[50]!,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(theme),
                        ),
                      )
                    : _buildPlaceholderImage(theme),
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.supplierName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green[900],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Price section - restructured to prevent overflow
                    if (product.discountPrice != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  '${product.discountPrice!.toStringAsFixed(0)} ${product.currency}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '/ ${product.unit}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.price.toStringAsFixed(0)} ${product.currency}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              '${product.price.toStringAsFixed(0)} ${product.currency}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '/ ${product.unit}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.green[300],
        ),
      ),
    );
  }
}
