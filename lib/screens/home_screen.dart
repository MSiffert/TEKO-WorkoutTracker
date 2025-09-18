import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workout_tracker/screens/stats_screen.dart';
import 'package:workout_tracker/screens/view_workout_screen.dart';

import 'add_workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _entriesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteEntry(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(docId)
        .delete();
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Workouts'),
        actions: [
          IconButton(
            tooltip: 'Ausloggen',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            tooltip: 'Statistiken',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Suche nach Titel oder Beschreibung',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _entriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Fehler: ${snapshot.error}'),
                  );
                }
                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || desc.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Hallo ${user.email ?? user.uid}\nNoch keine Workouts.'
                                : 'Keine Workouts zur Suche gefunden.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString();
                    final subtitle = (data['description'] ?? '').toString();

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
                            content: const Text('Dieses Workout wirklich löschen?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                            ],
                          ),
                        ) ??
                            false;
                      },
                      onDismissed: (_) => _deleteEntry(doc.id),
                      child: ListTile(
                        title: Text(title.isEmpty ? '(Ohne Titel)' : title),
                        subtitle: Text(subtitle.isEmpty ? 'Kein Text' : subtitle),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Löschen bestätigen'),
                                content: const Text('Dieses Workout wirklich löschen?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                                ],
                              ),
                            ) ??
                                false;

                            if (ok) {
                              await _deleteEntry(doc.id);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkoutViewScreen(workoutId: doc.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddWorkoutScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
      ),
    );
  }
}
