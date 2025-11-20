// lib/features/auth/presentation/consumer_sign_up_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/app_router.dart' show BuildContextX;
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_repository.dart';
import '../domain/entities/consumer_registration.dart';

class ConsumerSignUpPage extends StatefulWidget {
  const ConsumerSignUpPage({super.key});

  @override
  State<ConsumerSignUpPage> createState() => _ConsumerSignUpPageState();
}

class _ConsumerSignUpPageState extends State<ConsumerSignUpPage> {
  final _fullNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Kazakhstan');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _businessTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  AppLanguage _language = AppLanguage.en;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _countryCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _businessTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final fullName = _fullNameCtrl.text.trim();
    final businessName = _businessNameCtrl.text.trim();
    final country = _countryCtrl.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        fullName.isEmpty ||
        businessName.isEmpty ||
        country.isEmpty) {
      setState(() {
        _error = context.l10n.requiredFieldsMissing;
      });
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    final data = ConsumerSignUpData(
      email: email,
      password: password,
      fullName: fullName,
      language: _language,
      businessName: businessName,
      country: country,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      businessType:
          _businessTypeCtrl.text.trim().isEmpty ? null : _businessTypeCtrl.text.trim(),
      description:
          _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
    );

    try {
      final repo = context.read<AuthRepository>();
      await repo.registerConsumer(data);
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.consumerSignupTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.consumerSignupSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _fullNameCtrl,
              label: l10n.fullName,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _businessNameCtrl,
              label: l10n.businessName,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _countryCtrl,
              label: l10n.country,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _cityCtrl,
              label: '${l10n.city} ${l10n.optional}',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _addressCtrl,
              label: '${l10n.address} ${l10n.optional}',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _businessTypeCtrl,
              label: '${l10n.businessType} ${l10n.optional}',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descriptionCtrl,
              label: '${l10n.description} ${l10n.optional}',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneCtrl,
              label: '${l10n.phone} ${l10n.optional}',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailCtrl,
              label: l10n.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordCtrl,
              label: l10n.password,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppLanguage>(
              value: _language,
              decoration: InputDecoration(
                labelText: l10n.languageLabel,
                border: const OutlineInputBorder(),
              ),
              items: AppLanguage.values
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(lang.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _language = value);
              },
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            PrimaryButton(
              label: l10n.createAccountButton,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? (){} : _onSubmit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
              },
              child: Text(l10n.alreadyHaveAnAccount),
            ),
          ],
        ),
      ),
    );
  }
}

