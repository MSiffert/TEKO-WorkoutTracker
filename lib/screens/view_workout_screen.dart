import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_workout_screen.dart';

class WorkoutViewScreen extends StatelessWidget {
  final String workoutId;
  const WorkoutViewScreen({super.key, required this.workoutId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _docStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(workoutId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          IconButton(
            tooltip: 'Bearbeiten',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditWorkoutScreen(workoutId: workoutId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _docStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Fehler: ${snap.error}'));
          }
          final data = snap.data?.data();
          if (data == null) {
            return const Center(child: Text('Workout nicht gefunden.'));
          }

          final title = (data['title'] ?? '').toString();
          final desc  = (data['description'] ?? '').toString();
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final exercises = ((data['exercises'] ?? []) as List)
              .cast<Map<String, dynamic>>();

          double totalVolume = 0;
          for (final ex in exercises) {
            final sets = ((ex['sets'] ?? []) as List).cast<Map<String, dynamic>>();
            for (final s in sets) {
              final reps = (s['reps'] ?? 0) as int;
              final weight = (s['weight'] ?? 0).toDouble();
              totalVolume += reps * weight;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                title.isEmpty ? '(Ohne Titel)' : title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (createdAt != null)
                Text(
                  'Datum: ${_formatDate(createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(desc),
              ],
              const SizedBox(height: 16),
              if (exercises.isNotEmpty)
                Text('Übungen', style: Theme.of(context).textTheme.titleMedium),

              const SizedBox(height: 8),

              ...exercises.map((ex) {
                final name = (ex['name'] ?? '').toString();
                final sets = ((ex['sets'] ?? []) as List).cast<Map<String, dynamic>>();

                double exVolume = 0;
                for (final s in sets) {
                  final reps = (s['reps'] ?? 0) as int;
                  final weight = (s['weight'] ?? 0).toDouble();
                  exVolume += reps * weight;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name.isEmpty ? '(Übung)' : name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (exVolume > 0)
                              Text('${exVolume.toStringAsFixed(0)} kg Volumen'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...sets.asMap().entries.map((e) {
                          final idx = e.key + 1;
                          final s = e.value;
                          final reps = (s['reps'] ?? 0) as int;
                          final weight = (s['weight'] ?? 0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('#$idx',
                                      style: Theme.of(context).textTheme.bodySmall),
                                ),
                                const SizedBox(width: 8),
                                Text('$reps x ${weight.toStringAsFixed(1)} kg'),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
              if (totalVolume > 0)
                Text('Gesamtvolumen: ${totalVolume.toStringAsFixed(0)} kg',
                    style: Theme.of(context).textTheme.bodyMedium),
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy $hh:$min';
  }
}
