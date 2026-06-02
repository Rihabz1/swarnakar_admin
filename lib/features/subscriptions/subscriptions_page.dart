import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> {
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _displayDateFormat = DateFormat('dd MMM yyyy');

  DocumentSnapshot<Map<String, dynamic>>? _userSnapshot;
  bool _searching = false;
  bool _saving = false;
  String? _errorMessage;
  bool _isSubscribed = false;
  String _plan = 'monthly';
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
        _dateController.text = _displayDateFormat.format(picked);
      });
    }
  }

  Future<void> _searchUser() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a phone number to search.';
        _userSnapshot = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _errorMessage = null;
      _userSnapshot = null;
    });
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      final snapshot = await service
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (!mounted) return;
      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No user found with this phone number.';
          _userSnapshot = null;
        });
        return;
      }
      final doc = snapshot.docs.first;
      final data = doc.data();
      final subExpires = data['subExpires'];
      DateTime? expiresAt;
      if (subExpires is Timestamp) {
        expiresAt = subExpires.toDate();
      }
      setState(() {
        _userSnapshot = doc;
        _isSubscribed = data['isSubscribed'] == true;
        _plan = (data['plan']?.toString().isNotEmpty ?? false)
            ? data['plan'].toString()
            : 'monthly';
        _expiresAt = expiresAt;
        _dateController.text =
            expiresAt == null ? '' : _displayDateFormat.format(expiresAt);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Search failed: $error';
        _userSnapshot = null;
      });
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _save() async {
    final userSnapshot = _userSnapshot;
    if (userSnapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search for a user first.')),
      );
      return;
    }
    if (_expiresAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a subscription expiry date.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(adminFirestoreServiceProvider);
      await service.updateDoc('users', userSnapshot.id, {
        'isSubscribed': _isSubscribed,
        'plan': _plan,
        'subExpires': Timestamp.fromDate(_expiresAt!),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription info saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
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
        title: 'Subscription',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: '01XXXXXXXXX',
                      hintStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _searching ? null : _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: _searching
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4AF37),
                          ),
                        )
                      : const Text('অনুসন্ধান করুন'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            if (_userSnapshot != null) ...[
              _UserProfileCard(
                data: _userSnapshot!.data(),
                expiresAt: _expiresAt,
                displayDateFormat: _displayDateFormat,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _isSubscribed,
                        onChanged: (value) {
                          setState(() => _isSubscribed = value);
                        },
                        activeColor: const Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 8),
                      const Text('প্রিমিয়াম মেম্বারশিপ অ্যাক্টিভ'),
                    ],
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      value: _plan,
                      decoration: const InputDecoration(labelText: 'Plan'),
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'yearly',
                          child: Text('yearly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _plan = value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Subscription expires',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('সাবস্ক্রিপশন তথ্য সংরক্ষণ করুন'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({
    required this.data,
    required this.expiresAt,
    required this.displayDateFormat,
  });

  final Map<String, dynamic>? data;
  final DateTime? expiresAt;
  final DateFormat displayDateFormat;

  @override
  Widget build(BuildContext context) {
    final name = data?['name']?.toString() ?? 'Unknown';
    final phone = data?['phone']?.toString() ?? '-';
    final isSubscribed = data?['isSubscribed'] == true;
    final plan = data?['plan']?.toString() ?? '-';
    final expiresLabel =
        expiresAt == null ? 'Not set' : displayDateFormat.format(expiresAt!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text('Phone: $phone'),
          const Divider(height: 24),
          Text('Subscribed: ${isSubscribed ? 'Yes' : 'No'}'),
          Text('Plan: $plan'),
          Text('Expires: $expiresLabel'),
        ],
      ),
    );
  }
}
