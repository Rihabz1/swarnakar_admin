import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final settingsProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(adminFirestoreServiceProvider).watchDoc('settings', 'app');
});

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _currencyController = TextEditingController();
  final _localeController = TextEditingController();
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>?>>
      _settingsSubscription;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settingsSubscription =
        ref.listenManual<AsyncValue<Map<String, dynamic>?>>(
            settingsProvider, (prev, next) {
      if (!next.hasValue || _initialized) {
        return;
      }
      final data = next.value;
      if (data != null) {
        _companyController.text = data['companyName']?.toString() ?? '';
        _currencyController.text = data['currency']?.toString() ?? '';
        _localeController.text = data['locale']?.toString() ?? '';
      }
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _settingsSubscription.close();
    _companyController.dispose();
    _currencyController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      await service.setDoc('settings', 'app', {
        'companyName': _companyController.text.trim(),
        'currency': _currencyController.text.trim(),
        'locale': _localeController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    return SingleChildScrollView(
      child: SectionCard(
        title: 'App Settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (settingsAsync.isLoading && !_initialized)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(labelText: 'Company name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Company name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Currency is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _localeController,
                    decoration: const InputDecoration(labelText: 'Locale'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Locale is required.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
