import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  final Map<String, TextEditingController> _controllers = {
    'gold_21k': TextEditingController(),
    'gold_21k_old': TextEditingController(),
    'gold_22k': TextEditingController(),
    'gold_22k_old': TextEditingController(),
    'gold_paka': TextEditingController(),
    'gold_tukra': TextEditingController(),
    'silver_21k': TextEditingController(),
    'silver_22k': TextEditingController(),
    'silver_acid_kaim': TextEditingController(),
    'silver_chandi': TextEditingController(),
  };
  late final ProviderSubscription<AsyncValue<Map<String, dynamic>?>>
      _pricesSubscription;
  bool _initialized = false;
  bool _saving = false;

  final List<_PriceField> _fields = const [
    _PriceField(keyName: 'gold_21k', label: 'Gold 21K'),
    _PriceField(keyName: 'gold_21k_old', label: 'Gold 21K (Old)'),
    _PriceField(keyName: 'gold_22k', label: 'Gold 22K'),
    _PriceField(keyName: 'gold_22k_old', label: 'Gold 22K (Old)'),
    _PriceField(keyName: 'gold_paka', label: 'Gold Paka'),
    _PriceField(keyName: 'gold_tukra', label: 'Gold Tukra'),
    _PriceField(keyName: 'silver_21k', label: 'Silver 21K'),
    _PriceField(keyName: 'silver_22k', label: 'Silver 22K'),
    _PriceField(keyName: 'silver_acid_kaim', label: 'Silver Acid Kaim'),
    _PriceField(keyName: 'silver_chandi', label: 'Silver Chandi'),
  ];

  @override
  void initState() {
    super.initState();
    _pricesSubscription = ref.listenManual<AsyncValue<Map<String, dynamic>?>>(
        pricesProvider, (prev, next) {
      if (!next.hasValue || _initialized) {
        return;
      }
      final data = next.value;
      if (data != null) {
        for (final field in _fields) {
          _controllers[field.keyName]?.text =
              _formatNumber(data[field.keyName]);
        }
      }
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _pricesSubscription.close();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
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

  String? _formatUpdatedAt(dynamic value) {
    if (value == null) return null;
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }
    if (date == null) return null;
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      final data = <String, dynamic>{
        for (final field in _fields)
          field.keyName:
              double.parse(_controllers[field.keyName]!.text.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await service.setDoc('prices', 'current', {
        ...data,
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
    final updatedAtText = _formatUpdatedAt(pricesAsync.valueOrNull?['updatedAt']);
    final theme = Theme.of(context);
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
                  for (final field in _fields) ...[
                    TextFormField(
                      controller: _controllers[field.keyName],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: field.label,
                      ),
                      validator: _requiredNumber,
                    ),
                    const SizedBox(height: 16),
                  ],
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
            if (updatedAtText != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: $updatedAtText',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceField {
  const _PriceField({required this.keyName, required this.label});

  final String keyName;
  final String label;
}
