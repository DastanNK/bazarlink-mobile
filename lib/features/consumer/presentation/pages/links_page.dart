// lib/features/consumer/presentation/pages/links_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/consumer_models.dart';
import '../cart_provider.dart';
import 'product_detail_page.dart';

class LinksPage extends StatefulWidget {
  final ConsumerRepository repository;

  const LinksPage({super.key, required this.repository});

  @override
  State<LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<LinksPage> {
  late Future<List<LinkInfo>> _myLinksFuture;
  late Future<List<SupplierInfo>> _allSuppliersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showMySuppliers = true; // Default to "My Suppliers" tab
  String? _businessMessage;

  @override
  void initState() {
    super.initState();
    _myLinksFuture = widget.repository.getLinks();
    _allSuppliersFuture = widget.repository.getAllSuppliers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      _refreshSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _myLinksFuture = widget.repository.getLinks();
      _allSuppliersFuture = widget.repository.getAllSuppliers();
    });
  }

  Future<void> _refreshSuppliers() async {
    setState(() {
      _allSuppliersFuture = widget.repository.getAllSuppliers(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
    });
  }

  Future<void> _handleRequestLink(SupplierInfo supplier) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RequestLinkBottomSheet(
        supplier: supplier,
        initialMessage: _businessMessage,
      ),
    );

    if (result != null && result['action'] == 'send') {
      try {
      await widget.repository.requestLinkWithMessage(
        supplier.code,
        message: result['message'],
      );
        _businessMessage = result['message'];
        if (!mounted) return;
        // Small delay to ensure API has processed the request
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        // Force refresh both lists to get updated status
        setState(() {
          _myLinksFuture = widget.repository.getLinks();
          _allSuppliersFuture = widget.repository.getAllSuppliers(
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          );
        });
        if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.requestSent}: ${supplier.name}'),
          backgroundColor: Colors.green[700],
        ),
      );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _handleCancelRequest(String supplierCode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.cancelRequest),
        content: Text('Are you sure you want to cancel this link request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.cancelRequest),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.repository.cancelLinkRequest(supplierCode);
        if (!mounted) return;
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.requestCancelled),
            backgroundColor: Colors.orange[700],
          ),
        );
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

  void _navigateToBusinessDetails(SupplierInfo supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BusinessDetailsPage(
          supplier: supplier,
          repository: widget.repository,
          onRequestLink: () => _handleRequestLink(supplier),
          onCancelRequest: () => _handleCancelRequest(supplier.code),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border(
              bottom: BorderSide(color: Colors.green[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.linksInfoBanner,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green[900],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchSuppliers,
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

        // Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(l10n.mySuppliers),
                  selected: _showMySuppliers,
                  onSelected: (selected) {
                    setState(() {
                      _showMySuppliers = true;
                    });
                    // Refresh suppliers when switching tabs
                    _refreshSuppliers();
                  },
                  selectedColor: Colors.green[100],
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: _showMySuppliers ? Colors.green[900] : theme.colorScheme.onSurface,
                    fontWeight: _showMySuppliers ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _showMySuppliers ? Colors.green[700]! : theme.colorScheme.outline.withOpacity(0.3),
                      width: _showMySuppliers ? 2 : 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterChip(
                  label: Text(l10n.allSuppliers),
                  selected: !_showMySuppliers,
                  onSelected: (selected) {
                    setState(() {
                      _showMySuppliers = false;
                    });
                    // Refresh suppliers when switching tabs
                    _refreshSuppliers();
                  },
                  selectedColor: Colors.green[100],
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: !_showMySuppliers ? Colors.green[900] : theme.colorScheme.onSurface,
                    fontWeight: !_showMySuppliers ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: !_showMySuppliers ? Colors.green[700]! : theme.colorScheme.outline.withOpacity(0.3),
                      width: !_showMySuppliers ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Supplier List
        Expanded(
          child: _showMySuppliers
              ? _buildMySuppliersList(context, theme, l10n)
              : _buildAllSuppliersList(context, theme, l10n),
        ),
      ],
    );
  }

  Widget _buildMySuppliersList(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FutureBuilder<List<LinkInfo>>(
      future: _myLinksFuture,
            builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

        if (!snapshot.hasData) {
          return _buildEmptyMySuppliers(context, theme, l10n);
        }

        // Filter to show only accepted (linked) suppliers
        final links = snapshot.data!.where((link) => link.status == 'accepted').toList();
        
        if (links.isEmpty) {
          return _buildEmptyMySuppliers(context, theme, l10n);
        }

        // Get full supplier info for linked suppliers
        return FutureBuilder<List<SupplierInfo>>(
          future: _allSuppliersFuture,
          builder: (context, suppliersSnapshot) {
            if (!suppliersSnapshot.hasData) {
              return _buildEmptyMySuppliers(context, theme, l10n);
            }

            final allSuppliers = suppliersSnapshot.data!;
            final linkedSuppliers = links.map((link) {
              final supplier = allSuppliers.firstWhere(
                (s) => s.code == link.supplierCode,
                orElse: () => SupplierInfo(
                  id: link.id,
                  name: link.supplierName,
                  code: link.supplierCode ?? '',
                  city: link.city,
                  logoUrl: link.logoUrl,
                  status: link.status,
                ),
              );
              return supplier;
            }).toList();

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: linkedSuppliers.length,
                itemBuilder: (context, index) {
                  return _buildSupplierCard(context, theme, l10n, linkedSuppliers[index]);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllSuppliersList(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FutureBuilder<List<SupplierInfo>>(
      future: _allSuppliersFuture,
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
                  Icons.search_off,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No suppliers found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final suppliers = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refreshSuppliers,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              return _buildSupplierCard(context, theme, l10n, suppliers[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildSupplierCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SupplierInfo supplier,
  ) {
    final status = supplier.status;
    final isLinked = status == 'accepted';
    final isPending = status == 'pending';
    final isBlocked = status == 'blocked';
    final isNotLinked = status == null;

    Color statusColor;
    String statusText;
    if (isLinked) {
      statusColor = Colors.green;
      statusText = l10n.linked;
    } else if (isPending) {
      statusColor = Colors.orange;
      statusText = l10n.pending;
    } else if (isBlocked) {
      statusColor = Colors.red;
      statusText = l10n.blocked;
    } else {
      statusColor = Colors.grey;
      statusText = l10n.notLinked;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: isBlocked ? null : () => _navigateToBusinessDetails(supplier),
        child: Opacity(
          opacity: isBlocked ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Logo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: supplier.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                supplier.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.store,
                                  color: Colors.green[700],
                                  size: 30,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.store,
                              color: Colors.green[700],
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Supplier Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (supplier.category != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              supplier.category!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (supplier.city != null) ...[
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
                                  supplier.city!,
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
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: isBlocked ? Border.all(color: statusColor, width: 1) : null,
                      ),
                      child: Text(
                        statusText,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // Action buttons for Not linked and Pending
                if (isNotLinked || isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isNotLinked)
                        FilledButton(
                          onPressed: () => _handleRequestLink(supplier),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: Text(l10n.requestLink),
                        )
                      else if (isPending)
                        TextButton(
                          onPressed: () => _handleCancelRequest(supplier.code),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            l10n.cancelRequest,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMySuppliers(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 80,
              color: Colors.green[300],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noLinkedSuppliers,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noLinkedSuppliersMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _showMySuppliers = false;
                });
              },
              icon: const Icon(Icons.store),
              label: Text(l10n.browseSuppliers),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Business Details Page
class BusinessDetailsPage extends StatefulWidget {
  final SupplierInfo supplier;
  final ConsumerRepository repository;
  final VoidCallback onRequestLink;
  final VoidCallback onCancelRequest;

  const BusinessDetailsPage({
    super.key,
    required this.supplier,
    required this.repository,
    required this.onRequestLink,
    required this.onCancelRequest,
  });

  @override
  State<BusinessDetailsPage> createState() => _BusinessDetailsPageState();
}

class _BusinessDetailsPageState extends State<BusinessDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<SupplierProduct>> _productsFuture;
  late Future<List<String>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _searchAllProducts = false; // When true, search all products regardless of category

  @override
  void initState() {
    super.initState();
    final isLinked = widget.supplier.status == 'accepted';
    _tabController = TabController(length: isLinked ? 2 : 1, vsync: this);
    if (isLinked) {
      _categoriesFuture = widget.repository.getCategoriesForSupplier(widget.supplier.code);
      _productsFuture = widget.repository.getProductsBySupplier(widget.supplier.code);
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        if (_searchQuery.isNotEmpty) {
          _searchAllProducts = false; // Reset when typing
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      if (_searchQuery.isNotEmpty && _searchAllProducts) {
        // Load all products for search
        _productsFuture = widget.repository.getProductsBySupplier(widget.supplier.code);
      } else {
        _productsFuture = widget.repository.getProductsBySupplier(widget.supplier.code, category: _selectedCategory);
      }
    });
  }

  void _handleCategorySelection(String? category) {
    setState(() {
      // If clicking the same selected category, deselect (show all categories)
      if (_selectedCategory == category) {
        _selectedCategory = null;
        _searchQuery = '';
        _searchController.clear();
      } else {
        _selectedCategory = category;
        _searchQuery = '';
        _searchController.clear();
      }
      _refreshProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final status = widget.supplier.status;
    final isLinked = status == 'accepted';
    final isPending = status == 'pending';
    final isBlocked = status == 'blocked';
    final isNotLinked = status == null;

    Color statusColor;
    String statusText;
    if (isLinked) {
      statusColor = Colors.green;
      statusText = l10n.linked;
    } else if (isPending) {
      statusColor = Colors.orange;
      statusText = l10n.pending;
    } else if (isBlocked) {
      statusColor = Colors.red;
      statusText = l10n.blocked;
    } else {
      statusColor = Colors.grey;
      statusText = l10n.notLinked;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessDetails),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: isLinked
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: l10n.businessDetails),
                  Tab(text: l10n.catalog),
                ],
              )
            : null,
      ),
      body: isLinked
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(context, theme, l10n, statusColor, statusText, isNotLinked, isPending, isBlocked),
                _buildCatalogTab(context, theme, l10n),
              ],
            )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with logo and name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border(
                  bottom: BorderSide(color: Colors.green[200]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.supplier.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.supplier.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.store,
                                color: Colors.green[700],
                                size: 50,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.store,
                            color: Colors.green[700],
                            size: 50,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.supplier.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: isBlocked ? Border.all(color: statusColor, width: 1) : null,
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (widget.supplier.description != null) ...[
                    Text(
                      l10n.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.supplier.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Location
                  if (widget.supplier.city != null || widget.supplier.address != null) ...[
                    Text(
                      l10n.city,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.supplier.city != null)
                      _buildInfoRow(theme, Icons.location_on, widget.supplier.city!),
                    if (widget.supplier.address != null)
                      _buildInfoRow(theme, Icons.home, widget.supplier.address!),
                    if (widget.supplier.deliveryRegions != null && widget.supplier.deliveryRegions!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        theme,
                        Icons.local_shipping,
                        '${l10n.deliveryRegions}: ${widget.supplier.deliveryRegions!.join(", ")}',
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Order Terms
                  if (widget.supplier.minOrderAmount != null || widget.supplier.paymentTerms != null || widget.supplier.deliverySchedule != null) ...[
                    Text(
                      l10n.minOrder,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.supplier.minOrderAmount != null)
                      _buildInfoRow(theme, Icons.shopping_cart, '${widget.supplier.minOrderAmount!.toStringAsFixed(0)} ₸'),
                    if (widget.supplier.paymentTerms != null)
                      _buildInfoRow(theme, Icons.payment, widget.supplier.paymentTerms!),
                    if (widget.supplier.deliverySchedule != null)
                      _buildInfoRow(theme, Icons.calendar_today, widget.supplier.deliverySchedule!),
                    const SizedBox(height: 24),
                  ],

                  // Contact Info
                  if (widget.supplier.phone != null || widget.supplier.email != null || widget.supplier.website != null || widget.supplier.workingHours != null) ...[
                    Text(
                      l10n.contactInfo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.supplier.phone != null)
                      _buildInfoRow(theme, Icons.phone, widget.supplier.phone!),
                    if (widget.supplier.email != null)
                      _buildInfoRow(theme, Icons.email, widget.supplier.email!),
                    if (widget.supplier.website != null)
                      _buildInfoRow(theme, Icons.language, widget.supplier.website!),
                    if (widget.supplier.workingHours != null)
                      _buildInfoRow(theme, Icons.access_time, widget.supplier.workingHours!),
                    const SizedBox(height: 24),
                  ],

                  // Product Categories
                  if (widget.supplier.productCategories != null && widget.supplier.productCategories!.isNotEmpty) ...[
                    Text(
                      l10n.productCategories,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.supplier.productCategories!.map((category) {
                        return Chip(
                          label: Text(category),
                          backgroundColor: Colors.green[50],
                          labelStyle: TextStyle(color: Colors.green[900]),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),

            // Bottom Action Button
            if (!isBlocked)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: isNotLinked
                    ? FilledButton(
                        onPressed: widget.onRequestLink,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(l10n.requestLink),
                      )
                    : isPending
                        ? OutlinedButton(
                            onPressed: widget.onCancelRequest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              side: BorderSide(color: Colors.orange[700]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.cancelRequest),
                          )
                        : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Color statusColor,
    String statusText,
    bool isNotLinked,
    bool isPending,
    bool isBlocked,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with logo and name
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(
                bottom: BorderSide(color: Colors.green[200]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.supplier.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.supplier.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.store,
                              color: Colors.green[700],
                              size: 50,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.store,
                          color: Colors.green[700],
                          size: 50,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.supplier.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: isBlocked ? Border.all(color: statusColor, width: 1) : null,
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.supplier.description != null) ...[
                  Text(
                    l10n.description,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.supplier.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ],
                if (widget.supplier.city != null || widget.supplier.address != null) ...[
                  Text(
                    l10n.city,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.supplier.city != null)
                    _buildInfoRow(theme, Icons.location_on, widget.supplier.city!),
                  if (widget.supplier.address != null)
                    _buildInfoRow(theme, Icons.home, widget.supplier.address!),
                  if (widget.supplier.deliveryRegions != null && widget.supplier.deliveryRegions!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      theme,
                      Icons.local_shipping,
                      '${l10n.deliveryRegions}: ${widget.supplier.deliveryRegions!.join(", ")}',
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
                if (widget.supplier.minOrderAmount != null || widget.supplier.paymentTerms != null || widget.supplier.deliverySchedule != null) ...[
                  Text(
                    l10n.minOrder,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.supplier.minOrderAmount != null)
                    _buildInfoRow(theme, Icons.shopping_cart, '${widget.supplier.minOrderAmount!.toStringAsFixed(0)} ₸'),
                  if (widget.supplier.paymentTerms != null)
                    _buildInfoRow(theme, Icons.payment, widget.supplier.paymentTerms!),
                  if (widget.supplier.deliverySchedule != null)
                    _buildInfoRow(theme, Icons.calendar_today, widget.supplier.deliverySchedule!),
                  const SizedBox(height: 24),
                ],
                if (widget.supplier.phone != null || widget.supplier.email != null || widget.supplier.website != null || widget.supplier.workingHours != null) ...[
                  Text(
                    l10n.contactInfo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.supplier.phone != null)
                    _buildInfoRow(theme, Icons.phone, widget.supplier.phone!),
                  if (widget.supplier.email != null)
                    _buildInfoRow(theme, Icons.email, widget.supplier.email!),
                  if (widget.supplier.website != null)
                    _buildInfoRow(theme, Icons.language, widget.supplier.website!),
                  if (widget.supplier.workingHours != null)
                    _buildInfoRow(theme, Icons.access_time, widget.supplier.workingHours!),
                  const SizedBox(height: 24),
                ],
                if (widget.supplier.productCategories != null && widget.supplier.productCategories!.isNotEmpty) ...[
                  Text(
                    l10n.productCategories,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.supplier.productCategories!.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: Colors.green[50],
                        labelStyle: TextStyle(color: Colors.green[900]),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _searchAllProducts = false;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Search all products option (only shown when searching in a category)
              if (_searchQuery.isNotEmpty && _selectedCategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _searchAllProducts,
                        onChanged: (value) {
                          setState(() {
                            _searchAllProducts = value ?? false;
                            _refreshProducts();
                          });
                        },
                      ),
                      Text(
                        'Search in all products',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Show categories or products based on selection
        Expanded(
          child: _selectedCategory == null && _searchQuery.isEmpty
              ? _buildCategoriesView(context, theme, l10n)
              : _buildProductsView(context, theme, l10n),
        ),
      ],
    );
  }

  Widget _buildCategoriesView(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FutureBuilder<List<String>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No categories available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }
        final categories = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _categoriesFuture = widget.repository.getCategoriesForSupplier(widget.supplier.code);
            });
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(context, theme, l10n, category);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, ThemeData theme, AppLocalizations l10n, String category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _handleCategorySelection(category),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  size: 60,
                  color: Colors.green[700],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _getCategoryLocalized(category, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'meat':
        return Icons.set_meal;
      case 'dairy':
        return Icons.local_drink;
      default:
        return Icons.category;
    }
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

  Widget _buildProductsView(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FutureBuilder<List<SupplierProduct>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No products available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }
        final allProducts = snapshot.data!;
        final filteredProducts = allProducts.where((p) {
          if (_searchQuery.isEmpty) {
            // If no search, show products from selected category
            if (_selectedCategory != null) {
              return p.category == _selectedCategory;
            }
            return true;
          } else {
            // If searching
            if (_selectedCategory != null && !_searchAllProducts) {
              // Search only in selected category
              return p.category == _selectedCategory && 
                     p.productName.toLowerCase().contains(_searchQuery);
            } else {
              // Search all products
              return p.productName.toLowerCase().contains(_searchQuery);
            }
          }
        }).toList();
        
        return RefreshIndicator(
          onRefresh: _refreshProducts,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(context, theme, product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ThemeData theme, SupplierProduct product) {
    final l10n = context.l10n;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product detail
          final prod = Product(
            id: product.productId,
            name: product.productName,
            unit: product.unit,
            price: product.price,
            category: product.category,
            imageUrl: product.imageUrl,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: prod,
                repository: widget.repository,
                supplierCode: widget.supplier.code,
              ),
            ),
          );
        },
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
                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 40, color: Colors.grey[600]),
                        ),
                      )
                    : Icon(Icons.image, size: 40, color: Colors.grey[600]),
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
                    Text(
                      product.productName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ${product.currency}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/ ${product.unit}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () {
                        final cartProvider = context.read<CartProvider>();
                        final cartItem = CartItem(
                          productId: product.productId,
                          productName: product.productName,
                          supplierId: product.supplierId,
                          supplierCode: product.supplierCode,
                          price: product.price,
                          discountPrice: product.discountPrice,
                          currency: product.currency,
                          unit: product.unit,
                          imageUrl: product.imageUrl,
                          quantity: 1,
                        );
                        cartProvider.addItem(cartItem);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.productName} ${l10n.addToCart.toLowerCase()}'),
                              backgroundColor: Colors.green[700],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(l10n.addToCart),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
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

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
      ),
    );
  }
}

class _RequestLinkBottomSheet extends StatefulWidget {
  final SupplierInfo supplier;
  final String? initialMessage;

  const _RequestLinkBottomSheet({
    required this.supplier,
    this.initialMessage,
  });

  @override
  State<_RequestLinkBottomSheet> createState() => _RequestLinkBottomSheetState();
}

class _RequestLinkBottomSheetState extends State<_RequestLinkBottomSheet> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Text(
            l10n.requestLinkToSupplier,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Supplier name (read-only)
          TextFormField(
            initialValue: widget.supplier.name,
            readOnly: true,
            decoration: InputDecoration(
              labelText: l10n.supplier,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),
          // Business introduction
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: l10n.introduceBusiness,
              hintText: l10n.businessExample,
              border: const OutlineInputBorder(),
              helperText: l10n.businessExample,
              helperMaxLines: 2,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, {'action': 'cancel'}),
                  child: Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      {
                        'action': 'send',
                        'message': _messageController.text.trim(),
                      },
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.sendRequest),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
