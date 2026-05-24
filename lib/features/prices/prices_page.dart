import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final pricesProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchDoc('prices', 'current');
});

class PricesPage extends ConsumerStatefulWidget {
  const PricesPage({super.key});

  @override
  ConsumerState<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends ConsumerState<PricesPage> {
  final _formKey = GlobalKey<FormState>();
  final _gold24Controller = TextEditingController();
  final _gold22Controller = TextEditingController();
  final _gold18Controller = TextEditingController();
  final _silverController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<Map<String, dynamic>?>>(pricesProvider, (prev, next) {
      if (!next.hasValue || _initialized) {
        return;
      }
      final data = next.value;
      if (data != null) {
        _gold24Controller.text = _formatNumber(data['gold24k']);
        _gold22Controller.text = _formatNumber(data['gold22k']);
        _gold18Controller.text = _formatNumber(data['gold18k']);
        _silverController.text = _formatNumber(data['silver']);
      }
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _gold24Controller.dispose();
    _gold22Controller.dispose();
    _gold18Controller.dispose();
    _silverController.dispose();
    super.dispose();
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required.';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      await service.setDoc('prices', 'current', {
        'gold24k': double.parse(_gold24Controller.text.trim()),
        'gold22k': double.parse(_gold22Controller.text.trim()),
        'gold18k': double.parse(_gold18Controller.text.trim()),
        'silver': double.parse(_silverController.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices updated.')),
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
    final pricesAsync = ref.watch(pricesProvider);
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Current Prices',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pricesAsync.isLoading && !_initialized)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _gold24Controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gold 24K',
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gold22Controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gold 22K',
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gold18Controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gold 18K',
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _silverController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Silver',
                    ),
                    validator: _requiredNumber,
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
                    : const Text('Save prices'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
