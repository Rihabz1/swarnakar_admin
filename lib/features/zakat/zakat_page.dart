import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final zakatNisabProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(adminFirestoreServiceProvider).getDoc('zakat', 'nisab');
});

class ZakatPage extends ConsumerStatefulWidget {
  const ZakatPage({super.key});

  @override
  ConsumerState<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends ConsumerState<ZakatPage> {
  final _formKey = GlobalKey<FormState>();
  final _goldNisabController = TextEditingController();
  final _silverNisabController = TextEditingController();
  bool _saving = false;
  bool _initialized = false;
  DateTime? _lastUpdate;

  @override
  void dispose() {
    _goldNisabController.dispose();
    _silverNisabController.dispose();
    super.dispose();
  }

  void _syncFields(Map<String, dynamic>? data) {
    if (_initialized) {
      return;
    }
    if (data != null) {
      _goldNisabController.text = _formatNumber(data['gold_nisab']);
      _silverNisabController.text = _formatNumber(data['silver_nisab']);
      if (data['lastUpdate'] is Timestamp) {
        _lastUpdate = (data['lastUpdate'] as Timestamp).toDate();
      }
    }
    _initialized = true;
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
      final data = <String, dynamic>{
        'gold_nisab': double.parse(_goldNisabController.text.trim()),
        'silver_nisab': double.parse(_silverNisabController.text.trim()),
        'lastUpdate': FieldValue.serverTimestamp(),
      };
      await service.setDoc('zakat', 'nisab', data);

      // Update local lastUpdate display
      setState(() {
        _lastUpdate = DateTime.now();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zakat Nisab thresholds updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zakatAsync = ref.watch(zakatNisabProvider);

    if (zakatAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFields(zakatAsync.value);
      });
    }

    return SingleChildScrollView(
      child: SectionCard(
        title: 'Global Zakat Thresholds (Nisab)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (zakatAsync.isLoading && !_initialized)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (_lastUpdate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Last updated: ${DateFormat.yMMMd().add_jm().format(_lastUpdate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _goldNisabController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gold Nisab Threshold (in grams)',
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _silverNisabController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Silver Nisab Threshold (in grams)',
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
                child:
                    _saving
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Save Thresholds'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
