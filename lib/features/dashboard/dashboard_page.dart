import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';

final _usersCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchCollection('users')
      .map((docs) => docs.length);
});

final _subscriptionsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchCollection('subscriptions')
      .map((docs) => docs.length);
});

final _presetsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchCollection('calculator_presets')
      .map((docs) => docs.length);
});

final _priceHistoryCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(adminFirestoreServiceProvider)
      .watchCollection('price_history')
      .map((docs) => docs.length);
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersCount = ref.watch(_usersCountProvider).valueOrNull;
    final presetsCount = ref.watch(_presetsCountProvider).valueOrNull;
    final priceHistoryCount =
        ref.watch(_priceHistoryCountProvider).valueOrNull;
    final subscriptionsCount =
        ref.watch(_subscriptionsCountProvider).valueOrNull;

    final cards = [
      _StatCard(
        title: 'Users',
        value: usersCount?.toString() ?? '...',
      ),
      _StatCard(
        title: 'Presets',
        value: presetsCount?.toString() ?? '...',
      ),
      _StatCard(
        title: 'Price updates',
        value: priceHistoryCount?.toString() ?? '...',
      ),
      _StatCard(
        title: 'Subscriptions',
        value: subscriptionsCount?.toString() ?? '...',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick actions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const Text(
                  'Use the side navigation to manage prices, presets, and more.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
