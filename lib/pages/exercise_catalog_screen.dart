
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../repos/exercise_repo.dart';
import '../repos/workout_repo.dart';
import '../utils/helpers.dart';

class ExerciseCatalogScreen extends StatefulWidget {
  const ExerciseCatalogScreen({super.key});

  @override
  State<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends State<ExerciseCatalogScreen> {
  String q = '';
  String category = 'Alle';

  final defaultExercises = const [
    {'name': 'Bankdrücken Langhantel', 'category': 'Push', 'tags': ['Brust','Trizeps']},
    {'name': 'Schulterdrücken Kurzhantel', 'category': 'Push', 'tags': ['Schulter']},
    {'name': 'Kreuzheben', 'category': 'Pull', 'tags': ['Rücken','Hamstrings']},
    {'name': 'Klimmzüge', 'category': 'Pull', 'tags': ['Lat']},
    {'name': 'Rudern Kabel', 'category': 'Pull', 'tags': ['Rücken']},
    {'name': 'Kniebeugen', 'category': 'Legs', 'tags': ['Quadrizeps','Glutes']},
    {'name': 'Beinpresse', 'category': 'Legs', 'tags': ['Quadrizeps']},
    {'name': 'Hip Thrust', 'category': 'Legs', 'tags': ['Glutes']},
    {'name': 'Dips', 'category': 'Push', 'tags': ['Brust','Trizeps']},
    {'name': 'Bizepscurls', 'category': 'Pull', 'tags': ['Bizeps']},
  ];

  Future<void> _seedIfEmpty() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises');
    final snap = await col.limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final e in defaultExercises) {
        final nameStr = (e['name'] as String);
        final key = normalizeName(nameStr);
        final doc = col.doc(key);
        batch.set(doc, {'id': key, ...e, 'name': nameStr, 'nameKey': key, 'nameLower': nameStr.toLowerCase()});
      }
      await batch.commit();
    }
  }

  @override
  void initState() {
    super.initState();
    _seedIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final query = FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises');
    return Scaffold(
      appBar: AppBar(title: const Text('Übungskatalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Suche Übung...'),
                  onChanged: (v) => setState(() => q = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: category,
                items: const [
                  DropdownMenuItem(value: 'Alle', child: Text('Alle')),
                  DropdownMenuItem(value: 'Push', child: Text('Push')),
                  DropdownMenuItem(value: 'Pull', child: Text('Pull')),
                  DropdownMenuItem(value: 'Legs', child: Text('Legs')),
                  DropdownMenuItem(value: 'Full', child: Text('Full')),
                ],
                onChanged: (v) => setState(() => category = v ?? 'Alle'),
              )
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((d) {
                  final name = (d['name'] ?? '').toString().toLowerCase();
                  final cat = (d['category'] ?? '').toString();
                  final matchQ = q.isEmpty || name.contains(q.toLowerCase());
                  final matchC = category == 'Alle' || cat == category;
                  return matchQ && matchC;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Keine Übungen gefunden'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data();
                    final name = d['name'];
                    final cat = d['category'];
                    final tags = (d['tags'] as List?)?.cast<String>() ?? const [];
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
                            content: Text('Übung "$name" wirklich löschen?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (_) async {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises');
                        await col.doc(doc.id).delete();
      if (!mounted) return;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" gelöscht')));
                        }
                      },
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text([cat, if (tags.isNotEmpty) tags.join(', ')].join(' • ')),
                        trailing: Wrap(spacing: 8, children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () async {
                              final uid = FirebaseAuth.instance.currentUser!.uid;
                              final wRepo = WorkoutRepo(uid);
                              final exId = normalizeName(name);
                              final active = await wRepo.getOrStartActive(name: 'Workout');
                              await wRepo.addExercise(active.id, exerciseId: exId, name: name);
                              await wRepo.appendSets(active.id, exId, [{'reps': 8, 'weight': 0.0, 'rpe': 7.5}]);
                              if (context.mounted) snack(context, '$name zu Heute hinzugefügt');
                            },
                            tooltip: 'Zu Workout hinzufügen',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editExercise(d, doc.id),
                            tooltip: 'Bearbeiten',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Löschen bestätigen'),
                                  content: Text('Übung "$name" wirklich löschen?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                                  ],
                                ),
                              ) ?? false;
                              if (!ok) return;
                              final uid = FirebaseAuth.instance.currentUser!.uid;
                              final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises');
                              await col.doc(doc.id).delete();
                              if (context.mounted) snack(context, 'Gelöscht');
                            },
                            tooltip: 'Löschen',
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createExercise(context),
        icon: const Icon(Icons.create),
        label: const Text('Neue Übung'),
      ),
    );
  }

  Future<void> _createExercise(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String cat = 'Other';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Übung erstellen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'),),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cat,
              items: const [
                DropdownMenuItem(value: 'Push', child: Text('Push')),
                DropdownMenuItem(value: 'Pull', child: Text('Pull')),
                DropdownMenuItem(value: 'Legs', child: Text('Legs')),
                DropdownMenuItem(value: 'Full', child: Text('Full')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => cat = v ?? 'Other',
              decoration: const InputDecoration(labelText: 'Kategorie'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Speichern')),
        ],
      ),
    ) ?? false;
    if (!ok) return;
    final n = nameCtrl.text.trim();
    if (n.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = ExerciseRepo(uid);
    if (await repo.existsByKey(n)) {
      if (!mounted) return;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Übung existiert bereits')));
      return;
    }
    await repo.createIfNotExists(n, cat);
      if (!mounted) return;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Übung hinzugefügt')));
  }

  Future<void> _editExercise(Map<String, dynamic> data, String id) async {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    String cat = (data['category'] ?? 'Other').toString();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = ExerciseRepo(uid);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Übung bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cat,
              items: const [
                DropdownMenuItem(value: 'Push', child: Text('Push')),
                DropdownMenuItem(value: 'Pull', child: Text('Pull')),
                DropdownMenuItem(value: 'Legs', child: Text('Legs')),
                DropdownMenuItem(value: 'Full', child: Text('Full')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => cat = v ?? 'Other',
              decoration: const InputDecoration(labelText: 'Kategorie'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Speichern')),
        ],
      ),
    ) ?? false;

    if (!ok) return;
    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;

    final exists = await repo.existsByKey(newName);
    if (exists && normalizeName(newName) != id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Übung existiert bereits')));
      }
      return;
    }
    await repo.updateNameAndCategory(id: id, name: newName, category: cat);
      if (!mounted) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Übung aktualisiert')));
    }
  }
}