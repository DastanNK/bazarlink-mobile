// lib/features/sales/presentation/pages/sales_chat_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../../auth/data/auth_repository.dart';
import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';

class SalesChatPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesChatPage({super.key, required this.repository});

  @override
  State<SalesChatPage> createState() => _SalesChatPageState();
}

class _SalesChatPageState extends State<SalesChatPage> {
  late Future<List<SalesConsumer>> _consumersFuture;
  int? _selectedLinkId;
  late Future<List<SalesMessage>> _messagesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _textCtrl = TextEditingController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _consumersFuture = widget.repository.getLinkedConsumers();
    _messagesFuture = Future.value(<SalesMessage>[]);
    _loadCurrentUser();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final user = await authRepo.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_selectedLinkId == null) return;
    setState(() {
      _messagesFuture = widget.repository.getChatMessages(_selectedLinkId!);
    });
  }

  Future<void> _refreshConsumers() async {
    setState(() {
      _consumersFuture = widget.repository.getLinkedConsumers();
      if (_selectedLinkId != null) {
        _loadMessages();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    
    return FutureBuilder<List<SalesConsumer>>(
      future: _consumersFuture,
      builder: (context, consumersSnapshot) {
        if (consumersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!consumersSnapshot.hasData || consumersSnapshot.data!.isEmpty) {
          return _buildEmptyChatsState(context, theme, l10n);
        }
        
        // Filter to only assigned consumers
        final assignedConsumers = consumersSnapshot.data!
            .where((c) => c.assignedSalesRepId != null)
            .toList();
        
        if (assignedConsumers.isEmpty) {
          return _buildEmptyChatsState(context, theme, l10n);
        }
        
        // If a chat is selected, show chat detail
        if (_selectedLinkId != null) {
          final selectedConsumer = assignedConsumers.firstWhere(
            (c) => c.linkId == _selectedLinkId,
            orElse: () => assignedConsumers.first,
          );
          return _buildChatDetail(context, theme, l10n, selectedConsumer);
        }
        
        // Filter consumers by search query
        final filteredConsumers = _searchQuery.isEmpty
            ? assignedConsumers
            : assignedConsumers.where((c) => 
                c.name.toLowerCase().contains(_searchQuery)
              ).toList();
        
        // Otherwise, show list of chats
        return Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name...',
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
            // Chats list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshConsumers,
                child: filteredConsumers.isEmpty
                    ? Center(
                        child: Text(
                          'No chats found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredConsumers.length,
                        itemBuilder: (context, index) {
                          final consumer = filteredConsumers[index];
                          return _buildChatCard(context, theme, l10n, consumer);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyChatsState(BuildContext context, ThemeData theme, AppLocalizations l10n) {
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
              l10n.chat,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noAssignedConsumers,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateChatDialog(context, theme, l10n),
              icon: const Icon(Icons.add),
              label: const Text('Create New Chat'),
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

  Future<void> _showCreateChatDialog(BuildContext context, ThemeData theme, AppLocalizations l10n) async {
    // Get all consumers (not just assigned ones)
    final allConsumers = await widget.repository.getLinkedConsumers();
    if (!mounted) return;
    
    // Filter to only accepted consumers (not blocked, not rejected)
    final availableConsumers = allConsumers.where((c) => 
      c.status == 'accepted' || c.status == 'pending'
    ).toList();
    
    if (availableConsumers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No available consumers to chat with'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    
    final selected = await showDialog<SalesConsumer>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Consumer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableConsumers.length,
            itemBuilder: (context, index) {
              final consumer = availableConsumers[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
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
                title: Text(consumer.name),
                subtitle: consumer.city != null ? Text(consumer.city!) : null,
                onTap: () => Navigator.pop(context, consumer),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      // Check if chat already exists (link exists)
      if (selected.status == 'accepted') {
        // Chat already exists, just open it
        if (mounted) {
          setState(() {
            _selectedLinkId = selected.linkId;
            _loadMessages();
          });
        }
      } else {
        // Need to accept the link first if pending, or assign if not assigned
        if (selected.status == 'pending') {
          try {
            await widget.repository.acceptLink(selected.linkId);
            if (mounted) {
              setState(() {
                _selectedLinkId = selected.linkId;
                _loadMessages();
                _refreshConsumers();
              });
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red[700],
              ),
            );
          }
        } else if (selected.status == 'accepted' && selected.assignedSalesRepId == null) {
          // Assign to current sales rep
          try {
            await widget.repository.assignLink(selected.linkId);
            if (mounted) {
              setState(() {
                _selectedLinkId = selected.linkId;
                _loadMessages();
                _refreshConsumers();
              });
            }
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
    }
  }

  Widget _buildChatCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SalesConsumer consumer,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLinkId = consumer.linkId;
            _loadMessages();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Consumer icon
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
              // Consumer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consumer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (consumer.city != null) ...[
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
                            consumer.city!,
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
    SalesConsumer consumer,
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
                    _selectedLinkId = null;
                    _refreshConsumers();
                  });
                },
              ),
              const SizedBox(width: 8),
              // Consumer icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
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
                      consumer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (consumer.city != null)
                      Text(
                        consumer.city!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: FutureBuilder<List<SalesMessage>>(
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
                  return _buildMessageBubble(context, theme, message);
                },
              );
            },
          ),
        ),
        // Message input
        _buildMessageInput(context, theme, l10n),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme, SalesMessage message) {
    final isMe = _currentUserId != null && message.senderId == _currentUserId;
    
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
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

  Widget _buildMessageInput(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              decoration: InputDecoration(
                hintText: l10n.typeMessage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.green[700]),
            onPressed: () async {
              if (_textCtrl.text.trim().isEmpty || _selectedLinkId == null) return;
              try {
                await widget.repository
                    .sendMessage(_selectedLinkId!, _textCtrl.text.trim());
                _textCtrl.clear();
                if (!mounted) return;
                await _loadMessages();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.error}: $e'),
                    backgroundColor: Colors.red[700],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
