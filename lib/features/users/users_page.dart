import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/section_card.dart';

final usersProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchCollection('users', orderBy: 'createdAt', descending: true);
});

class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final isCompact = MediaQuery.of(context).size.width < 860;

    return usersAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        if (isCompact) {
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final role = data['role']?.toString() ?? 'staff';
              return SectionCard(
                title: data['name']?.toString() ?? 'User',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${data['email'] ?? '--'}'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _updateRole(ref, doc.id, value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Role'),
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
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Role')),
            ],
            rows: [
              for (final doc in docs)
                DataRow(cells: [
                  DataCell(Text(doc.data()['name']?.toString() ?? '--')),
                  DataCell(Text(doc.data()['email']?.toString() ?? '--')),
                  DataCell(
                    DropdownButton<String>(
                      value: doc.data()['role']?.toString() ?? 'staff',
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _updateRole(ref, doc.id, value);
                        }
                      },
                    ),
                  ),
                ]),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _updateRole(WidgetRef ref, String userId, String role) async {
    await ref.read(adminFirestoreServiceProvider).updateDoc('users', userId, {
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
