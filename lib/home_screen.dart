
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_entry_screen.dart';
import 'pages/exercise_catalog_screen.dart';
import 'pages/quick_log_screen.dart';
import 'pages/stats_screen.dart';
import 'pages/dashboard_screen.dart';
import 'pages/workout_detail_screen.dart';
import 'utils/helpers.dart';
import 'repos/workout_repo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _workoutsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return WorkoutRepo(uid).streamRecent(limitCount: 100);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Workouts'),
        actions: [
          IconButton(
            onPressed: () async {
              final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
      if (!mounted) return;
              if (res == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktualisiert')));
              }
            },
            icon: const Icon(Icons.space_dashboard),
            tooltip: 'Dashboard',
          ),
          IconButton(
            onPressed: () async {
              final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExerciseCatalogScreen()));
      if (!mounted) return;
              if (res == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Katalog aktualisiert')));
              }
            },
            icon: const Icon(Icons.fitness_center),
            tooltip: 'Katalog',
          ),
          IconButton(
            onPressed: () async {
              final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuickLogScreen()));
      if (!mounted) return;
              if (res == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gespeichert')));
              }
            },
            icon: const Icon(Icons.bolt),
            tooltip: 'Quick Log',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            icon: const Icon(Icons.emoji_events),
            tooltip: 'PR & Stats',
          ),
          IconButton(
            tooltip: 'Ausloggen',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _workoutsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Hallo ${user.email ?? user.uid}\nNoch keine Workouts.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final repo = WorkoutRepo(uid);
                        final active = await repo.getOrStartActive(name: 'Workout');
      if (!mounted) return;
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: active.id)));
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Workout starten'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = (data['name'] ?? 'Workout').toString();
              final status = (data['status'] ?? 'in_progress').toString();
              final startedAtClient = (data['startedAtClient'] as Timestamp?)?.toDate() ?? DateTime.now();
              final exs = (data['exercises'] as List?) ?? [];
              int exercisesCount = exs.length;
              int setsCount = 0;
              double volume = 0.0;
              for (final e in exs) {
                final sets = (e['sets'] as List?) ?? [];
                setsCount += sets.length;
                for (final s in sets) {
                  final r = (s['reps'] as num?)?.toInt() ?? 0;
                  final w = (s['weight'] as num?)?.toDouble() ?? 0.0;
                  volume += r * w;
                }
              }

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Löschen bestätigen'),
                      content: const Text('Workout wirklich löschen?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (_) async {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  final repo = WorkoutRepo(uid);
                  final backup = data;
                  await repo.delete(doc.id);
      if (!mounted) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Workout gelöscht'),
                      action: SnackBarAction(label: 'Rückgängig', onPressed: () async {
                        await repo.restore(doc.id, backup);
                      }),
                    ));
                  }
                },
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('${status == 'completed' ? 'Abgeschlossen' : 'Laufend'} • ${yyyymmdd(startedAtClient)} • ${exercisesCount} Üb. / ${setsCount} Sätze • Vol ${volume.toStringAsFixed(0)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: doc.id)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final uid = FirebaseAuth.instance.currentUser!.uid;
          final repo = WorkoutRepo(uid);
          final active = await repo.getOrStartActive(name: 'Workout');
      if (!mounted) return;
          if (context.mounted) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: active.id)));
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Workout'),
      ),
    );
  }
}