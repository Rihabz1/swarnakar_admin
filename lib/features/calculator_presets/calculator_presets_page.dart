import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final presetsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchCollection('calculator_presets', orderBy: 'createdAt');
});

class CalculatorPresetsPage extends ConsumerWidget {
  const CalculatorPresetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetsProvider);
    final isCompact = MediaQuery.of(context).size.width < 860;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _openPresetDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add preset'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: presetsAsync.when(
            data: (docs) {
              if (docs.isEmpty) {
                return const Center(child: Text('No presets found.'));
              }
              if (isCompact) {
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return SectionCard(
                      title: data['name']?.toString() ?? 'Preset',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Purity: ${data['purity'] ?? '--'}'),
                          Text('Wastage %: ${data['wastagePercent'] ?? '--'}'),
                          Text('Making charge: ${data['makingCharge'] ?? '--'}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _openPresetDialog(
                                  context,
                                  ref,
                                  presetId: doc.id,
                                  presetData: data,
                                ),
                                child: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _deletePreset(ref, doc.id),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              return SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Purity')),
                    DataColumn(label: Text('Wastage %')),
                    DataColumn(label: Text('Making charge')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final doc in docs)
                      DataRow(cells: [
                        DataCell(Text(doc.data()['name']?.toString() ?? '')),
                        DataCell(Text(doc.data()['purity']?.toString() ?? '')),
                        DataCell(
                            Text(doc.data()['wastagePercent']?.toString() ?? '')),
                        DataCell(
                            Text(doc.data()['makingCharge']?.toString() ?? '')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _openPresetDialog(
                                context,
                                ref,
                                presetId: doc.id,
                                presetData: doc.data(),
                              ),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _deletePreset(ref, doc.id),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        )),
                      ]),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  Future<void> _deletePreset(WidgetRef ref, String id) async {
    await ref.read(adminFirestoreServiceProvider).deleteDoc(
          'calculator_presets',
          id,
        );
  }

  Future<void> _openPresetDialog(
    BuildContext context,
    WidgetRef ref, {
    String? presetId,
    Map<String, dynamic>? presetData,
  }) async {
    final nameController =
        TextEditingController(text: presetData?['name']?.toString() ?? '');
    final purityController =
        TextEditingController(text: presetData?['purity']?.toString() ?? '');
    final wastageController = TextEditingController(
        text: presetData?['wastagePercent']?.toString() ?? '');
    final makingController = TextEditingController(
        text: presetData?['makingCharge']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(presetId == null ? 'Add preset' : 'Edit preset'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: purityController,
                    decoration: const InputDecoration(labelText: 'Purity'),
                    keyboardType: TextInputType.number,
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: wastageController,
                    decoration:
                        const InputDecoration(labelText: 'Wastage percent'),
                    keyboardType: TextInputType.number,
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: makingController,
                    decoration:
                        const InputDecoration(labelText: 'Making charge'),
                    keyboardType: TextInputType.number,
                    validator: _requiredNumber,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                final service = ref.read(adminFirestoreServiceProvider);
                if (presetId == null) {
                  final doc = service.collection('calculator_presets').doc();
                  await doc.set({
                    'name': nameController.text.trim(),
                    'purity': double.parse(purityController.text.trim()),
                    'wastagePercent':
                        double.parse(wastageController.text.trim()),
                    'makingCharge':
                        double.parse(makingController.text.trim()),
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await service.updateDoc('calculator_presets', presetId, {
                    'name': nameController.text.trim(),
                    'purity': double.parse(purityController.text.trim()),
                    'wastagePercent':
                        double.parse(wastageController.text.trim()),
                    'makingCharge':
                        double.parse(makingController.text.trim()),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
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
