
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/progression_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final workouts = FirebaseFirestore.instance.collection('users').doc(uid).collection('workouts').orderBy('startedAtClient', descending: true);

    final ps = ProgressionService();

    return Scaffold(
      appBar: AppBar(title: const Text('PR & Stats')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: workouts.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.docs;

          final Map<String, double> best = {};
          for (final doc in data) {
            final exs = (doc['exercises'] as List?) ?? [];
            for (final e in exs) {
              final name = (e['name'] ?? '').toString();
              final sets = (e['sets'] as List?) ?? [];
              for (final s in sets) {
                final reps = (s['reps'] as num?)?.toInt() ?? 0;
                final weight = (s['weight'] as num?)?.toDouble() ?? 0.0;
                final est = ps.estimate1RM(weight: weight, reps: reps);
                if (est > (best[name] ?? 0.0)) best[name] = est;
              }
            }
          }

          if (best.isEmpty) return const Center(child: Text('Noch keine Daten'));
          final entries = best.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => ListTile(
              title: Text(entries[i].key),
              trailing: Text('${entries[i].value.toStringAsFixed(1)} kg'),
            ),
          );
        },
      ),
    );
  }
}