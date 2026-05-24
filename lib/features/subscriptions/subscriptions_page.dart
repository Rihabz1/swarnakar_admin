import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final subscriptionProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchDoc('subscriptions', 'current');
});

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  final _formKey = GlobalKey<FormState>();
  final _planController = TextEditingController();
  final _statusController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _expiresAt;
  bool _initialized = false;
  bool _saving = false;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<Map<String, dynamic>?>>(subscriptionProvider,
        (prev, next) {
      if (!next.hasValue || _initialized) {
        return;
      }
      final data = next.value;
      if (data != null) {
        _planController.text = data['plan']?.toString() ?? '';
        _statusController.text = data['status']?.toString() ?? '';
        final ts = data['expiresAt'];
        if (ts is Timestamp) {
          _expiresAt = ts.toDate();
          _dateController.text = _dateFormat.format(_expiresAt!);
        }
      }
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _planController.dispose();
    _statusController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = picked;
        _dateController.text = _dateFormat.format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_expiresAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an expiry date.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      await service.setDoc('subscriptions', 'current', {
        'plan': _planController.text.trim(),
        'status': _statusController.text.trim(),
        'expiresAt': Timestamp.fromDate(_expiresAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription updated.')),
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
    final subscriptionAsync = ref.watch(subscriptionProvider);
    return SingleChildScrollView(
      child: SectionCard(
        title: 'Subscription',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subscriptionAsync.isLoading && !_initialized)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _planController,
                    decoration: const InputDecoration(labelText: 'Plan'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Plan is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Status is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Expires at',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: _pickDate,
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
                    : const Text('Save subscription'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
