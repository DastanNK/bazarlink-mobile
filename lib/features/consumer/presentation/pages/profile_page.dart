// lib/features/consumer/presentation/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/localization_provider.dart';
import '../../../../core/routing/app_router.dart' show BuildContextX;
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/entities/user.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green[100],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.email,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.role.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Settings Section
          Text(
            'Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Language Selection
          Card(
            child: Consumer<LocalizationProvider>(
              builder: (context, langProvider, _) {
                return ExpansionTile(
                  leading: Icon(Icons.language, color: Colors.green[700]),
                  title: Text('Language / Тіл / Язык'),
                  subtitle: Text(langProvider.language.displayName),
                  children: AppLanguage.values.map((lang) {
                    return RadioListTile<AppLanguage>(
                      title: Text(lang.displayName),
                      value: lang,
                      groupValue: langProvider.language,
                      onChanged: (value) {
                        if (value != null) {
                          langProvider.setLanguage(value);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Account Information
          Text(
            'Account Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email, color: Colors.green[700]),
                  title: Text('Email'),
                  subtitle: Text(user.email),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.badge, color: Colors.green[700]),
                  title: Text('Role'),
                  subtitle: Text(user.role.name),
                ),
                if (user.consumerId != null) ...[
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.person_outline, color: Colors.green[700]),
                    title: Text('Consumer ID'),
                    subtitle: Text('${user.consumerId}'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.green[700]),
              title: Text('App Version'),
              subtitle: Text('1.0.0'),
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text(l10n.logout),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.logout),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.logout),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await context.read<AuthRepository>().logout();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
