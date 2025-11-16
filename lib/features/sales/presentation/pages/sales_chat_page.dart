// lib/features/sales/presentation/pages/sales_chat_page.dart
import 'package:flutter/material.dart';

import '../../data/sales_repository.dart';
import '../../domain/entities/sales_models.dart';

class SalesChatPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesChatPage({super.key, required this.repository});

  @override
  State<SalesChatPage> createState() => _SalesChatPageState();
}

class _SalesChatPageState extends State<SalesChatPage> {
  int _selectedConsumerId = 1;
  late Future<List<SalesMessage>> _future;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getChatMessages(_selectedConsumerId);
  }

  Future<void> _load() async {
    setState(() {
      _future = widget.repository.getChatMessages(_selectedConsumerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // простейший выбор consumerId
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('Consumer ID:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedConsumerId,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1')),
                  DropdownMenuItem(value: 2, child: Text('2')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedConsumerId = v);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<SalesMessage>>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final msgs = snapshot.data!;
              return ListView.builder(
                reverse: true,
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[msgs.length - 1 - i];
                  final isMe = m.from == 'You';
                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${m.from}: ${m.text}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Type message...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () async {
                  if (_textCtrl.text.trim().isEmpty) return;
                  await widget.repository
                      .sendMessage(_selectedConsumerId, _textCtrl.text.trim());
                  _textCtrl.clear();
                  if (!mounted) return;
                  await _load();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
