import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final zakatYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

final zakatDocProvider = FutureProvider.family<Map<String, dynamic>?, int>(
  (ref, year) {
    return ref
        .watch(adminFirestoreServiceProvider)
        .getDoc('zakat', year.toString());
  },
);

class ZakatPage extends ConsumerStatefulWidget {
  const ZakatPage({super.key});

  @override
  ConsumerState<ZakatPage> createState() => _ZakatPageState();
}

class _ZakatPageState extends ConsumerState<ZakatPage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _nisabController = TextEditingController();
  final _assetsController = TextEditingController();
  final _liabilitiesController = TextEditingController();
  final _zakatDueController = TextEditingController();
  int? _loadedYear;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _nisabController.dispose();
    _assetsController.dispose();
    _liabilitiesController.dispose();
    _zakatDueController.dispose();
    super.dispose();
  }

  void _syncFields(Map<String, dynamic>? data, int year) {
    if (_loadedYear == year) {
      return;
    }
    _nisabController.text = _formatNumber(data?['nisab']);
    _assetsController.text = _formatNumber(data?['assets']);
    _liabilitiesController.text = _formatNumber(data?['liabilities']);
    _zakatDueController.text = _formatNumber(data?['zakatDue']);
    _loadedYear = year;
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

  Future<void> _loadYear() async {
    final parsed = int.tryParse(_yearController.text.trim());
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid year.')),
      );
      return;
    }
    ref.read(zakatYearProvider.notifier).state = parsed;
  }

  Future<void> _save(int year) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      final existing = await service.getDoc('zakat', year.toString());
      final data = <String, dynamic>{
        'nisab': double.parse(_nisabController.text.trim()),
        'assets': double.parse(_assetsController.text.trim()),
        'liabilities': double.parse(_liabilitiesController.text.trim()),
        'zakatDue': double.parse(_zakatDueController.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (existing == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      await service.setDoc('zakat', year.toString(), data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zakat updated.')),
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
    final year = ref.watch(zakatYearProvider);
    final zakatAsync = ref.watch(zakatDocProvider(year));

    if (zakatAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFields(zakatAsync.value, year);
      });
    }

    return SingleChildScrollView(
      child: SectionCard(
        title: 'Zakat',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Year'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadYear,
                  child: const Text('Load'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (zakatAsync.isLoading && _loadedYear != year)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nisabController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nisab'),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _assetsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Assets'),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _liabilitiesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Liabilities'),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _zakatDueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Zakat due'),
                    validator: _requiredNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(year),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save zakat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
