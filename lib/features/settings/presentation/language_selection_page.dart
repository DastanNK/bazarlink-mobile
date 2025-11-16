// lib/features/settings/presentation/language_selection_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/localization_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_router.dart' show BuildContextX;

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.chooseLanguage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            for (final lang in AppLanguage.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: FilledButton(
                  onPressed: () {
                    provider.setLanguage(lang);
                    Navigator.of(context).pushReplacementNamed(AppRouter.login);
                  },
                  child: Text(lang.displayName),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
