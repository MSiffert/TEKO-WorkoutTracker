import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _entriesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiken')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _entriesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Fehler: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          final Map<String, _ExerciseStats> stats = {};

          double toDouble(dynamic v) {
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
            return 0.0;
          }

          for (final d in docs) {
            final data = d.data();
            final exercises = ((data['exercises'] ?? []) as List).cast<Map<String, dynamic>>();
            for (final ex in exercises) {
              final name = (ex['name'] ?? '').toString().trim();
              if (name.isEmpty) continue;

              stats.putIfAbsent(name, () => _ExerciseStats());

              final sets = ((ex['sets'] ?? []) as List).cast<Map<String, dynamic>>();
              for (final s in sets) {
                final reps = (s['reps'] ?? 0);
                final repsInt = (reps is int) ? reps : int.tryParse(reps.toString()) ?? 0;
                final weight = toDouble(s['weight']);

                final score = weight * repsInt;
                final st = stats[name]!;
                st.totalSets += 1;
                st.totalVolume += score;

                if (score > st.strongestScore) {
                  st.strongestScore = score;
                  st.strongestWeight = weight;
                  st.strongestReps = repsInt;
                }
              }
            }
          }

          if (stats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Noch keine Daten für Statistiken vorhanden.'),
              ),
            );
          }

          final entries = stats.entries.toList()
            ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final name = entries[i].key;
              final st = entries[i].value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Stärkster Satz',
                            value: st.strongestScore <= 0
                                ? '-'
                                : '${st.strongestWeight.toStringAsFixed(1)} kg × ${st.strongestReps}',
                          ),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Total Sätze', value: '${st.totalSets}'),
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Total Volumen',
                            value: '${st.totalVolume.toStringAsFixed(0)} kg',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExerciseStats {
  int totalSets = 0;
  double totalVolume = 0.0;
  double strongestScore = 0.0;
  double strongestWeight = 0.0;
  int strongestReps = 0;
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
