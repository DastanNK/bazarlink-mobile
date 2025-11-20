// lib/features/sales/presentation/pages/sales_complaints_page.dart
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';

class SalesComplaintsPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesComplaintsPage({super.key, required this.repository});

  @override
  State<SalesComplaintsPage> createState() => _SalesComplaintsPageState();
}

class _SalesComplaintsPageState extends State<SalesComplaintsPage> {
  late Future<List<SalesComplaint>> _future;
  final TextEditingController _resolutionController = TextEditingController();
  final TextEditingController _escalationController = TextEditingController();
  final TextEditingController _managerIdController = TextEditingController();
  int? _selectedComplaintId;
  late Future<List<SalesMessage>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getComplaints();
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    _escalationController.dispose();
    _managerIdController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.repository.getComplaints();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'escalated':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleResolve(SalesComplaint complaint) async {
    final l10n = context.l10n;
    _resolutionController.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resolveComplaint),
        content: TextField(
          controller: _resolutionController,
          decoration: InputDecoration(
            labelText: l10n.resolutionNote,
            hintText: l10n.enterResolutionDetails,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _resolutionController.text),
            child: Text(l10n.resolve),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await widget.repository.resolveComplaint(complaint.id, resolution: result);
        if (!mounted) return;
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.complaintResolved),
            backgroundColor: Colors.green[700],
          ),
        );
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

  Future<void> _handleEscalate(SalesComplaint complaint) async {
    final l10n = context.l10n;
    _escalationController.clear();
    _managerIdController.clear();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.escalateComplaint),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _managerIdController,
              decoration: InputDecoration(
                labelText: l10n.managerUserId,
                hintText: l10n.enterManagerUserId,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _escalationController,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                hintText: l10n.enterEscalationNote,
                border: const OutlineInputBorder(),
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
              final managerId = _managerIdController.text.trim();
              if (managerId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.managerIdRequired)),
                );
                return;
              }
              Navigator.pop(context, {
                'managerId': managerId,
                'note': _escalationController.text.trim(),
              });
            },
            child: Text(l10n.escalate),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final managerId = int.tryParse(result['managerId'] ?? '');
        if (managerId == null) {
          throw Exception(l10n.invalidManagerId);
        }
        await widget.repository.escalateComplaint(
          complaint.id,
          managerUserId: managerId,
          note: result['note']?.isEmpty == true ? null : result['note'],
        );
        if (!mounted) return;
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.complaintEscalated),
            backgroundColor: Colors.orange[700],
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return FutureBuilder<List<SalesComplaint>>(
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
                  Icons.check_circle_outline,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noComplaints,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
        final list = snapshot.data!;
        
        // If a complaint is selected, show chat detail
        if (_selectedComplaintId != null) {
          final selectedComplaint = list.firstWhere(
            (c) => c.id == _selectedComplaintId,
            orElse: () => list.first,
          );
          return _buildComplaintChat(context, theme, l10n, selectedComplaint);
        }
        
        // Otherwise, show list of complaints
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              final statusColor = _getStatusColor(c.status);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: c.status == 'open' || c.status == 'in_progress' ? 2 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: (c.status == 'open' || c.status == 'in_progress')
                      ? BorderSide(color: Colors.red[300]!, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedComplaintId = c.id;
                      // Get complaint chat messages using link_id
                      final linkId = c.linkId ?? c.id; // Fallback to complaint id if link_id not available
                      _messagesFuture = widget.repository.getChatMessages(linkId);
                    });
                  },
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
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.report_problem,
                                color: Colors.red[700],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.consumerName,
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
                                c.status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (c.description != null && c.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            c.description!,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Open Chat',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildComplaintChat(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    SalesComplaint complaint,
  ) {
    final statusColor = _getStatusColor(complaint.status);
    final canResolve = complaint.status == 'open' || complaint.status == 'in_progress';
    final canEscalate = complaint.status == 'open' || complaint.status == 'in_progress';
    
    return Column(
      children: [
        // Complaint header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedComplaintId = null;
                        _refresh();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.report_problem,
                      color: Colors.red[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          complaint.consumerName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                      complaint.status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (complaint.description != null && complaint.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    complaint.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              if (canResolve || canEscalate) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (canResolve)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _handleResolve(complaint),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n.resolve),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (canResolve && canEscalate) const SizedBox(width: 8),
                    if (canEscalate)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleEscalate(complaint),
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: Text(l10n.escalate),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(color: Colors.orange[700]!),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
        _buildMessageInput(context, theme, l10n, complaint),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, ThemeData theme, SalesMessage message) {
    // This would need to check current user ID to determine if message is from current user
    final isMe = false; // TODO: Get current user ID and compare
    
    return Align(
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
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMe ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, ThemeData theme, AppLocalizations l10n, SalesComplaint complaint) {
    final textController = TextEditingController();
    final linkId = complaint.linkId ?? complaint.id; // Fallback to complaint id if link_id not available
    
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
              controller: textController,
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
              if (textController.text.trim().isEmpty) return;
              try {
                await widget.repository.sendMessage(linkId, textController.text.trim());
                textController.clear();
                if (!mounted) return;
                setState(() {
                  _messagesFuture = widget.repository.getChatMessages(linkId);
                });
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
