import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../services/session_document_cache.dart';
import '../../widgets/section_card.dart';

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
  bool _hasUserEdited = false;
  bool _syncingFromDatabase = false;
  bool _loading = false;
  String? _errorMessage;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _goldNisabController.addListener(_markUserEdited);
    _silverNisabController.addListener(_markUserEdited);
    _loadZakat();
  }

  @override
  void dispose() {
    _goldNisabController.removeListener(_markUserEdited);
    _silverNisabController.removeListener(_markUserEdited);
    _goldNisabController.dispose();
    _silverNisabController.dispose();
    super.dispose();
  }

  void _markUserEdited() {
    if (_initialized && !_syncingFromDatabase) {
      _hasUserEdited = true;
    }
  }

  void _syncFields(Map<String, dynamic>? data) {
    _syncingFromDatabase = true;
    if (data != null) {
      _goldNisabController.text = _formatNumber(data['gold_nisab']);
      _silverNisabController.text = _formatNumber(data['silver_nisab']);
      if (data['lastUpdate'] is Timestamp) {
        _lastUpdate = (data['lastUpdate'] as Timestamp).toDate();
      }
    }
    _syncingFromDatabase = false;
    _initialized = true;
  }

  Future<void> _refresh() async {
    _hasUserEdited = false;
    await _loadZakat(forceRefresh: true);
  }

  Future<void> _loadZakat({bool forceRefresh = false}) async {
    if (SessionDocumentCache.has('zakat', 'nisab') && !forceRefresh) {
      final cached = SessionDocumentCache.get('zakat', 'nisab');
      _syncFields(cached);
      setState(() => _errorMessage = null);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final data = await SessionDocumentCache.load(
        ref.read(adminFirestoreServiceProvider),
        'zakat',
        'nisab',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      if (!_hasUserEdited) {
        _syncFields(data);
      }
    } catch (error) {
      if (!mounted) return;
      _errorMessage =
          'Failed to load zakat thresholds. Use Refresh to try again.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
      _hasUserEdited = false;
      await _loadZakat(forceRefresh: true);

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
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Global Zakat Thresholds (Nisab)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading && !_initialized)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
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
                OutlinedButton.icon(
                  onPressed: _loading || _saving ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
