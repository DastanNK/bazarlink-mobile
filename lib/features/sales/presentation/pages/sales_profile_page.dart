// lib/features/sales/presentation/pages/sales_profile_page.dart
import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../../auth/domain/entities/user.dart';

class SalesProfilePage extends StatelessWidget {
  final User user;

  const SalesProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.email),
          title: Text(user.email),
        ),
        ListTile(
          leading: const Icon(Icons.badge),
          title: Text('Role: ${user.role.name}'),
        ),
        ListTile(
          leading: const Icon(Icons.store),
          title: Text('Supplier ID: ${user.supplierId ?? '-'}'),
        ),
        const SizedBox(height: 16),
        Text(
          'Here later:\n'
          '- notification settings\n'
          '- language switch\n'
          '- escalations overview',
        ),
      ],
    );
  }
}
