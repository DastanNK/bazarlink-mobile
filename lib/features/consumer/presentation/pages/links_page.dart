// lib/features/consumer/presentation/pages/links_page.dart
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
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
      await widget.repository.requestLinkWithMessage(
        supplier.code,
        message: result['message'],
      );
      _businessMessage = result['message'];
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.requestSent}: ${supplier.name}'),
          backgroundColor: Colors.green[700],
        ),
      );
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
      await widget.repository.cancelLinkRequest(supplierCode);
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request cancelled'),
          backgroundColor: Colors.orange[700],
        ),
      );
    }
  }

  void _handleOpenCatalog(String supplierCode) {
    // Navigate to catalog and filter by this supplier
    // This would be handled by parent navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening catalog for supplier...'),
        backgroundColor: Colors.green[700],
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

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return _buildSupplierCard(
                context,
                theme,
                l10n,
                SupplierInfo(
                  id: link.id,
                  name: link.supplierName,
                  code: link.supplierCode ?? '',
                  city: link.city,
                  logoUrl: link.logoUrl,
                  status: link.status,
                ),
              );
            },
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
            // Status and Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                const SizedBox(height: 8),
                if (isLinked)
                  FilledButton(
                    onPressed: () => _handleOpenCatalog(supplier.code),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(l10n.openCatalog),
                  )
                else if (isPending)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.requestSent,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _handleCancelRequest(supplier.code),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.cancelRequest,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  )
                else if (isNotLinked)
                  FilledButton(
                    onPressed: () => _handleRequestLink(supplier),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(l10n.requestLink),
                  ),
              ],
            ),
          ],
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
              l10n.sendLinkRequestToStart,
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
