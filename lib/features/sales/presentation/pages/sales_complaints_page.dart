// lib/features/sales/presentation/pages/sales_complaints_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/entities/manager_info.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/value_objects.dart';

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
  int? _selectedComplaintId;
  late Future<List<SalesMessage>> _messagesFuture;
  String _selectedStatusFilter = 'all'; // 'all', 'open', 'in_progress', 'resolved', 'escalated'
  UserRole? _currentUserRole;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _future = widget.repository.getComplaints();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final user = await authRepo.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUserRole = user.role;
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      debugPrint('Failed to load current user: $e');
    }
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    _escalationController.dispose();
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
        
        // Send message to customer about resolution
        if (complaint.linkId != null) {
          try {
            await widget.repository.sendMessage(
              complaint.linkId!,
              'Your complaint has been resolved. Resolution: $result',
            );
          } catch (e) {
            // Log error but don't fail the resolution
            debugPrint('Failed to send resolution message: $e');
          }
        }
        
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
    
    // Load managers
    final managersFuture = widget.repository.getManagers();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => FutureBuilder<List<ManagerInfo>>(
        future: managersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: Text(l10n.escalateComplaint),
              content: const Center(child: CircularProgressIndicator()),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return AlertDialog(
              title: Text(l10n.escalateComplaint),
              content: const Text('No managers available'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ],
            );
          }
          
          final managers = snapshot.data!;
          ManagerInfo? selectedManager;
          
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(l10n.escalateComplaint),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ManagerInfo>(
                    decoration: InputDecoration(
                      labelText: 'Select Manager',
                      border: const OutlineInputBorder(),
                    ),
                    value: selectedManager,
                    items: managers.map((manager) {
                      return DropdownMenuItem<ManagerInfo>(
                        value: manager,
                        child: Text('${manager.name} (${manager.email})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedManager = value;
                      });
                    },
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
                  onPressed: selectedManager == null
                      ? null
                      : () {
                          Navigator.pop(context, {
                            'managerId': selectedManager!.id.toString(),
                            'note': _escalationController.text.trim(),
                          });
                        },
                  child: Text(l10n.escalate),
                ),
              ],
            ),
          );
        },
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
        
        // Filter complaints by role: sales reps should NOT see escalated complaints
        // Managers should ONLY see escalated complaints (escalated to them specifically)
        final roleFilteredList = list.where((c) {
          if (_currentUserRole == UserRole.sales_representative) {
            // Sales reps should NOT see escalated complaints
            return c.status != 'escalated' && !c.isEscalated;
          } else if (_currentUserRole == UserRole.manager) {
            // Managers should ONLY see escalated complaints escalated to them
            if (_currentUserId == null) {
              return false; // Can't determine if escalated to this manager
            }
            // Must be escalated status AND escalated to this specific manager
            if (c.escalatedToUserId != null) {
              return c.status == 'escalated' && c.escalatedToUserId == _currentUserId;
            }
            // If no escalated_to_user_id, don't show it (shouldn't happen, but safety check)
            return false;
          } else if (_currentUserRole == UserRole.owner) {
            // Owners can see all complaints
            return true;
          }
          // Default: show all if role is unknown (fallback)
          return true;
        }).toList();
        
        // Filter complaints by status
        final filteredList = _selectedStatusFilter == 'all'
            ? roleFilteredList
            : roleFilteredList.where((c) => c.status == _selectedStatusFilter).toList();
        
        // If a complaint is selected, show chat detail
        if (_selectedComplaintId != null) {
          final selectedComplaint = list.firstWhere(
            (c) => c.id == _selectedComplaintId,
            orElse: () => list.first,
          );
          return _buildComplaintChat(context, theme, l10n, selectedComplaint);
        }
        
        // Otherwise, show list of complaints with status filter tabs
        return Column(
          children: [
            // Status filter tabs
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatusTab(theme, l10n, 'all', 'All'),
                    const SizedBox(width: 8),
                    // Only show non-escalated status tabs for sales reps
                    if (_currentUserRole != UserRole.manager) ...[
                      _buildStatusTab(theme, l10n, 'open', 'Open'),
                      const SizedBox(width: 8),
                      _buildStatusTab(theme, l10n, 'in_progress', 'In Progress'),
                      const SizedBox(width: 8),
                    ],
                    // Only show escalated tab for managers, or if user is owner
                    if (_currentUserRole == UserRole.manager || _currentUserRole == UserRole.owner) ...[
                      _buildStatusTab(theme, l10n, 'escalated', 'Escalated'),
                      const SizedBox(width: 8),
                    ],
                    _buildStatusTab(theme, l10n, 'resolved', 'Resolved'),
                  ],
                ),
              ),
            ),
            // Complaints list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: filteredList.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (_, i) {
                          final c = filteredList[i];
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
                                    // Description removed - only show title as requested
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
                    ),
                  ),
              ],
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
    // Sales reps can resolve/escalate non-escalated complaints
    // Managers can resolve escalated complaints
    final canResolve = _currentUserRole == UserRole.manager
        ? complaint.status == 'escalated'
        : (complaint.status == 'open' || complaint.status == 'in_progress');
    final canEscalate = _currentUserRole == UserRole.sales_representative &&
        (complaint.status == 'open' || complaint.status == 'in_progress');
    
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
              // Description removed - only show title as requested
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
    // Get sender role from message - need to check if backend provides this
    // For now, we'll need to fetch user info to determine role
    final senderRole = message.senderRole; // This field needs to be added back to SalesMessage
    
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
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
                      senderRole == 'manager' ? context.l10n.manager : context.l10n.salesRepresentative,
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
        ),
      ],
    );
  }

  Widget _buildStatusTab(ThemeData theme, AppLocalizations l10n, String status, String label) {
    final isSelected = _selectedStatusFilter == status;
    final statusColor = _getStatusColor(status == 'all' ? 'open' : status);
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = status;
        });
      },
      selectedColor: statusColor.withOpacity(0.2),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      checkmarkColor: statusColor,
      labelStyle: TextStyle(
        color: isSelected ? statusColor : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
