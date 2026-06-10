import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_providers.dart';
import '../../services/session_document_cache.dart';
import '../../widgets/section_card.dart';

class NoticePage extends ConsumerStatefulWidget {
  const NoticePage({super.key});

  @override
  ConsumerState<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends ConsumerState<NoticePage> {
  final _formKey = GlobalKey<FormState>();
  final _noticeController = TextEditingController();
  bool _initialized = false;
  bool _hasUserEdited = false;
  bool _syncingFromDatabase = false;
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _noticeController.addListener(_markUserEdited);
    _loadNotice();
  }

  void _markUserEdited() {
    if (_initialized && !_syncingFromDatabase) {
      _hasUserEdited = true;
    }
  }

  void _syncField(Map<String, dynamic>? data) {
    _syncingFromDatabase = true;
    _noticeController.text = data?['notice']?.toString() ?? '';
    _syncingFromDatabase = false;
    _initialized = true;
  }

  Future<void> _refresh() async {
    _hasUserEdited = false;
    await _loadNotice(forceRefresh: true);
  }

  Future<void> _loadNotice({bool forceRefresh = false}) async {
    if (SessionDocumentCache.has('prices', 'current') && !forceRefresh) {
      final cached = SessionDocumentCache.get('prices', 'current');
      _data = cached;
      _syncField(cached);
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
        'prices',
        'current',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      _data = data;
      if (!_hasUserEdited) {
        _syncField(data);
      }
    } catch (error) {
      if (!mounted) return;
      _errorMessage = 'Failed to load notice. Use Refresh to try again.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _noticeController.removeListener(_markUserEdited);
    _noticeController.dispose();
    super.dispose();
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
      await service.setDoc('prices', 'current', {
        'notice': _noticeController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _hasUserEdited = false;
      await _loadNotice(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notice updated.')));
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
    final updatedAtText = _formatUpdatedAt(_data?['updatedAt']);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: SectionCard(
        title: 'Current Notice',
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
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _noticeController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Notice',
                  alignLabelWithHint: true,
                ),
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
                          : const Text('Save notice'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading || _saving ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            if (updatedAtText != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: $updatedAtText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
