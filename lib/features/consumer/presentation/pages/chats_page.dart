// lib/features/consumer/presentation/pages/chats_page.dart
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/consumer_repository.dart';
import '../../domain/entities/consumer_models.dart';
import 'product_detail_page.dart';

class ChatsPage extends StatefulWidget {
  final ConsumerRepository repository;

  const ChatsPage({super.key, required this.repository});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Future<List<Chat>> _chatsFuture;
  int? _selectedChatId;
  late Future<List<ChatMessage>> _messagesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _chatsFuture = widget.repository.getChats();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshChats() async {
    setState(() {
      _chatsFuture = widget.repository.getChats();
      if (_selectedChatId != null) {
        _messagesFuture = widget.repository.getChatMessages(_selectedChatId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FutureBuilder<List<Chat>>(
      future: _chatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyChatsState(context, theme, l10n);
        }

        final chats = snapshot.data!;

        if (_selectedChatId != null) {
          final selectedChat = chats.firstWhere((c) => c.id == _selectedChatId);
          return _buildChatDetail(context, theme, l10n, selectedChat);
        }

        // Filter chats by search query
        final filteredChats = _searchQuery.isEmpty
            ? chats
            : chats.where((c) => 
                c.supplierName.toLowerCase().contains(_searchQuery)
              ).toList();
        
        return RefreshIndicator(
          onRefresh: _refreshChats,
          child: Column(
            children: [
              // Create new chat button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showCreateChatDialog(context, theme, l10n),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Chat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by supplier name...',
                    prefixIcon: Icon(Icons.search, color: Colors.green[700]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Chats list
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Text(
                          'No chats found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return _buildChatCard(context, theme, l10n, chat);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Chat chat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: chat.isComplaint ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: chat.isComplaint
            ? BorderSide(color: Colors.red[300]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedChatId = chat.id;
            _messagesFuture = widget.repository.getChatMessages(chat.id);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Supplier logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: chat.supplierLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          chat.supplierLogoUrl!,
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
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.supplierName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (chat.isComplaint)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.report_problem, size: 14, color: Colors.red[700]),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.complaints,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(chat.lastMessageAt, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatDetail(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    Chat chat,
  ) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedChatId = null;
                    _refreshChats();
                  });
                },
              ),
              const SizedBox(width: 8),
              // Supplier logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: chat.supplierLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          chat.supplierLogoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.store,
                            color: Colors.green[700],
                            size: 20,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.store,
                        color: Colors.green[700],
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.supplierName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (chat.isComplaint) ...[
                      Text(
                        l10n.complaints,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                      if (chat.isEscalated) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.escalator_warning, size: 14, color: Colors.purple[700]),
                            const SizedBox(width: 4),
                            Text(
                              chat.escalatedToManagerName != null
                                  ? 'Escalated to ${chat.escalatedToManagerName}'
                                  : 'Escalated to Manager',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: FutureBuilder<List<ChatMessage>>(
            future: _messagesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noMessagesYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }

              final messages = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(context, theme, l10n, message);
                },
              );
            },
          ),
        ),
        // Message input
        _buildMessageInput(context, theme, l10n, chat.id),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme, AppLocalizations l10n, ChatMessage message) {
    final isMe = message.isFromConsumer;
    final isEscalated = message.isEscalated;
    final senderRole = message.senderRole;
    
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Escalation indicator
        if (isEscalated && !isMe)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, size: 14, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  l10n.escalatedToManager,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        // Sender role badge - show at top of message bubble for manager/sales
        if (senderRole != null && !isMe)
          Padding(
            padding: EdgeInsets.only(
              bottom: 4,
              left: isMe ? 0 : 8,
              right: isMe ? 8 : 0,
            ),
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: senderRole == 'manager' ? Colors.purple[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: senderRole == 'manager' ? Colors.purple[300]! : Colors.blue[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      senderRole == 'manager' ? Icons.badge : Icons.person,
                      size: 14,
                      color: senderRole == 'manager' ? Colors.purple[700] : Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      senderRole == 'manager' ? l10n.manager : l10n.salesRepresentative,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: senderRole == 'manager' ? Colors.purple[700] : Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.green[700] : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt attachment
                if (message.receiptUrl != null) ...[
                  InkWell(
                    onTap: () {
                      // Show receipt in full screen
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.receipt,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, size: 60, color: Colors.grey[600]),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${l10n.receiptNumber} #${message.id}',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: isMe ? Colors.white : Colors.grey[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.viewReceipt,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Product link
                if (message.productId != null && message.productName != null) ...[
                  InkWell(
                    onTap: () async {
                      // Navigate to product detail
                      final products = await widget.repository.getCatalog();
                      final product = products.firstWhere(
                        (p) => p.id == message.productId,
                        orElse: () => products.first,
                      );
                      if (context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              product: product,
                              repository: widget.repository,
                              supplierCode: '',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green[800] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMe ? Colors.green[600]! : Colors.blue[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag,
                            color: isMe ? Colors.white : Colors.blue[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.productLink,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isMe ? Colors.white70 : Colors.blue[700],
                                  ),
                                ),
                                Text(
                                  message.productName!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: isMe ? Colors.white70 : Colors.blue[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Image attachment
                if (message.imageUrl != null) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image, size: 40, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Audio attachment
                if (message.audioUrl != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[800] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.audiotrack,
                          color: isMe ? Colors.white : Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Audio message',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tap to play',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            color: isMe ? Colors.white : Colors.blue[700],
                          ),
                          onPressed: () {
                            // TODO: Implement audio playback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.audioPlaybackNotImplemented)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // File attachment
                if (message.fileUrl != null) ...[
                  InkWell(
                    onTap: () {
                      // TODO: Open/download file
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.fileDownloadNotImplemented)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMe ? Colors.green[600]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMe ? Colors.white : Colors.grey[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.fileName ?? 'File attachment',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tap to download',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.download,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Message text
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 4),
                // Timestamp
                Text(
                  '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChatsState(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return FutureBuilder<List<LinkInfo>>(
      future: widget.repository.getLinkedSuppliers(),
      builder: (context, suppliersSnapshot) {
        final hasLinkedSuppliers = suppliersSnapshot.hasData && suppliersSnapshot.data!.isNotEmpty;
        
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.green[300],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.chats,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noChatsYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasLinkedSuppliers) ...[
                  const SizedBox(height: 32),
                  Text(
                    l10n.startChatWith,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...suppliersSnapshot.data!.map((link) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: link.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    link.logoUrl!,
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
                        title: Text(link.supplierName),
                        trailing: Icon(Icons.chat, color: Colors.green[700]),
                        onTap: () async {
                          if (link.supplierCode != null) {
                            // Get supplier info to get supplierId
                            final allSuppliers = await widget.repository.getAllSuppliers();
                            final supplier = allSuppliers.firstWhere(
                              (s) => s.code == link.supplierCode,
                              orElse: () => SupplierInfo(
                                id: 0,
                                name: link.supplierName,
                                code: link.supplierCode!,
                              ),
                            );
                            
                            final chatId = await widget.repository.startChatWithSupplier(
                              supplier.id,
                              link.supplierCode!,
                            );
                            
                            if (mounted) {
                              setState(() {
                                _selectedChatId = chatId;
                                _messagesFuture = widget.repository.getChatMessages(chatId);
                                _chatsFuture = widget.repository.getChats();
                              });
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    int chatId,
  ) {
    return _MessageInputWidget(
      repository: widget.repository,
      chatId: chatId,
      onMessageSent: () {
        setState(() {
          _chatsFuture = widget.repository.getChats();
          _messagesFuture = widget.repository.getChatMessages(chatId);
        });
      },
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${l10n.daysAgo}';
    } else {
      final months = [
        l10n.jan, l10n.feb, l10n.mar, l10n.apr, l10n.may, l10n.jun,
        l10n.jul, l10n.aug, l10n.sep, l10n.oct, l10n.nov, l10n.dec
      ];
      return '${date.day} ${months[date.month - 1]}';
    }
  }

  Future<void> _showCreateChatDialog(BuildContext context, ThemeData theme, AppLocalizations l10n) async {
    final suppliers = await widget.repository.getLinkedSuppliers();
    if (!mounted) return;
    
    final selected = await showDialog<LinkInfo>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Supplier'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
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
                title: Text(supplier.supplierName),
                onTap: () => Navigator.pop(context, supplier),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null && selected.supplierCode != null) {
      final allSuppliers = await widget.repository.getAllSuppliers();
      final supplier = allSuppliers.firstWhere(
        (s) => s.code == selected.supplierCode,
        orElse: () => SupplierInfo(
          id: selected.id,
          name: selected.supplierName,
          code: selected.supplierCode!,
        ),
      );
      
      // Check if chat already exists by checking current chats
      final currentChats = await widget.repository.getChats();
      final existingChat = currentChats.firstWhere(
        (c) => c.supplierId == supplier.id,
        orElse: () => Chat(
          id: -1,
          supplierId: -1,
          supplierName: '',
          lastMessageAt: DateTime.now(),
        ),
      );
      
      int chatId;
      if (existingChat.id != -1 && existingChat.supplierId == supplier.id) {
        // Chat already exists, use it
        chatId = existingChat.id;
      } else {
        // Create new chat
        chatId = await widget.repository.startChatWithSupplier(
          supplier.id,
          selected.supplierCode!,
        );
      }
      
      if (mounted) {
        setState(() {
          _selectedChatId = chatId;
          _messagesFuture = widget.repository.getChatMessages(chatId);
          _chatsFuture = widget.repository.getChats();
        });
      }
    }
  }
}

class _MessageInputWidget extends StatefulWidget {
  final ConsumerRepository repository;
  final int chatId;
  final VoidCallback onMessageSent;

  const _MessageInputWidget({
    required this.repository,
    required this.chatId,
    required this.onMessageSent,
  });

  @override
  State<_MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<_MessageInputWidget> {
  final TextEditingController _textController = TextEditingController();
  String? _selectedImagePath;
  String? _selectedReceiptPath;
  int? _selectedProductId;
  String? _selectedProductName;
  bool _showCannedReplies = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty && 
        _selectedImagePath == null && 
        _selectedReceiptPath == null && 
        _selectedProductId == null) {
      return;
    }

    await widget.repository.sendMessage(
      widget.chatId,
      _textController.text.trim(),
      imageUrl: _selectedImagePath,
      receiptUrl: _selectedReceiptPath,
      productId: _selectedProductId,
    );

    _textController.clear();
    setState(() {
      _selectedImagePath = null;
      _selectedReceiptPath = null;
      _selectedProductId = null;
      _selectedProductName = null;
    });

    widget.onMessageSent();
  }

  Future<void> _pickImage() async {
    // Mock image picker - in real app, use image_picker package
    setState(() {
      _selectedImagePath = 'https://via.placeholder.com/300';
    });
  }

  Future<void> _pickReceipt() async {
    // Mock receipt picker
    setState(() {
      _selectedReceiptPath = 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
    });
  }

  Future<void> _selectProduct() async {
    final products = await widget.repository.getCatalog();
    if (!mounted) return;

    final selected = await showDialog<Product>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.attachProduct),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('${product.price.toStringAsFixed(0)} ₸ / ${product.unit}'),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedProductId = selected.id;
        _selectedProductName = selected.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attachments preview
        if (_selectedImagePath != null || _selectedReceiptPath != null || _selectedProductId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                if (_selectedImagePath != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Icon(Icons.image, size: 24)),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() => _selectedImagePath = null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_selectedReceiptPath != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          l10n.receipt,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() => _selectedReceiptPath = null);
                          },
                        ),
                      ],
                    ),
                  ),
                if (_selectedProductId != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          _selectedProductName ?? l10n.product,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selectedProductId = null;
                              _selectedProductName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        // Canned replies
        if (_showCannedReplies)
          FutureBuilder<List<String>>(
            future: widget.repository.getCannedReplies(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final reply = snapshot.data![index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(reply),
                        onSelected: (selected) {
                          _textController.text = reply;
                          setState(() => _showCannedReplies = false);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        // Input field
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              // Attachment button
              PopupMenuButton<String>(
                icon: Icon(Icons.attach_file, color: Colors.green[700]),
                onSelected: (value) {
                  if (value == 'image') {
                    _pickImage();
                  } else if (value == 'receipt') {
                    _pickReceipt();
                  } else if (value == 'product') {
                    _selectProduct();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'image',
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.attachFile),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'receipt',
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.attachReceipt),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'product',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.attachProduct),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Canned replies button
              IconButton(
                icon: Icon(
                  _showCannedReplies ? Icons.close : Icons.quickreply,
                  color: Colors.green[700],
                ),
                onPressed: () {
                  setState(() => _showCannedReplies = !_showCannedReplies);
                },
                tooltip: l10n.cannedReplies,
              ),
              const SizedBox(width: 8),
              // Text input
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: l10n.typeMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              IconButton(
                icon: Icon(Icons.send, color: Colors.green[700]),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
