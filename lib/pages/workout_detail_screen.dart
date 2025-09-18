import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workout_tracker/repos/workout_repo.dart';
import '../repos/exercise_repo.dart';
import '../services/pr_service.dart';
import '../utils/helpers.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _pending = false;
  bool _loading = true;
  Map<String, dynamic>? _data;
  late final WorkoutRepo _repo;
  late final ExerciseRepo _exRepo;
  late final PRService _pr;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = WorkoutRepo(uid);
    _exRepo = ExerciseRepo(uid);
    _pr = PRService(uid);

    _sub = _repo.stream(widget.workoutId).listen((doc) {
      if (!mounted) return;
      setState(() {
        _data = doc.data();
        _loading = false;
        _pending = doc.metadata.hasPendingWrites;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = (_data?['name'] ?? 'Workout').toString();
    final status = (_data?['status'] ?? 'in_progress').toString();
    final exercises = (_data?['exercises'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(name),
            if (_pending) const SizedBox(width: 8),
            if (_pending) const Icon(Icons.sync, size: 16),
          ],
        ),
        actions: [
          if (status != 'completed')
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Abschliessen',
              onPressed: () async {
                await _repo.complete(widget.workoutId);
                if (mounted) snack(context, 'Workout abgeschlossen');
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final ctrl = TextEditingController(text: name);
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Workout umbenennen'),
                      content: TextField(controller: ctrl),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Abbrechen'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Speichern'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok) return;
              await _repo.rename(
                  widget.workoutId, ctrl.text.trim());
              if (mounted) snack(context, 'Gespeichert');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _addExerciseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Übung hinzufügen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            exercises.length,
            (i) => _exerciseCard(i, exercises[i]),
          ),
        ],
      ),
    );
  }

  Future<void> _addExerciseDialog() async {
    final names = await _exRepo.listNamesOnce();
    String selected = '';
    TextEditingController? fieldCtrl;

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Übung wählen'),
            content: Autocomplete<String>(
              optionsBuilder: (tev) {
                final q = tev.text.trim();
                if (q.isEmpty) {
                  return const Iterable<String>.empty();
                }
                final low = q.toLowerCase();
                return names.where(
                    (e) => e.toLowerCase().contains(low));
              },
              onSelected: (v) {
                selected = v;
                fieldCtrl?.text = v;
              },
              fieldViewBuilder:
                  (c, controller, focus, onSubmitted) {
                fieldCtrl = controller;
                return TextField(
                  controller: controller,
                  focusNode: focus,
                  decoration: const InputDecoration(
                      labelText: 'Name'),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final input = (fieldCtrl?.text ?? '').trim();
    final name = (selected.isNotEmpty ? selected : input).trim();
    if (name.isEmpty) return;

    await _exRepo.createIfNotExists(name, 'Other');
    final key = normalizeName(name);
    await _repo.addExercise(
      widget.workoutId,
      exerciseId: key,
      name: name,
    );
    if (mounted) snack(context, 'Übung hinzugefügt');
  }

  Widget _exerciseCard(int index, Map<String, dynamic> ex) {
    final sets = (ex['sets'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    final name = (ex['name'] ?? '').toString();

    double vol = 0.0;
    for (final s in sets) {
      final r = (s['reps'] as num?)?.toInt() ?? 0;
      final w = (s['weight'] as num?)?.toDouble() ?? 0.0;
      vol += r * w;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style:
                        Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('Vol: ${vol.toStringAsFixed(0)}'),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Übung entfernen?'),
                            content: Text('"$name" aus Workout entfernen?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Abbrechen'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Entfernen'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!ok) return;

                    final backup =
                        Map<String, dynamic>.from(ex);

                    await _repo.removeExercise(
                        widget.workoutId, index);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$name" entfernt'),
                        action: SnackBarAction(
                          label: 'Rückgängig',
                          onPressed: () async {
                            await _repo.insertExerciseAt(
                              widget.workoutId,
                              index,
                              backup,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Column(
              children: [
                for (int i = 0; i < sets.length; i++)
                  _setRow(index, i, sets[i]),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final newSets =
                          List<Map<String, dynamic>>.from(sets)
                            ..add({'reps': 8, 'weight': 0.0, 'rpe': 7.5});
                      await _repo.updateExercise(
                        widget.workoutId,
                        index,
                        {...ex, 'sets': newSets},
                      );
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Satz hinzufügen'),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _setRow(
      int exIndex, int setIndex, Map<String, dynamic> set) {
    final repsCtrl = TextEditingController(
        text: '${(set['reps'] as num?)?.toInt() ?? 0}');
    final weightCtrl = TextEditingController(
        text: '${(set['weight'] as num?)?.toDouble() ?? 0.0}');
    final rpeCtrl = TextEditingController(
        text: '${(set['rpe'] as num?)?.toDouble() ?? 0.0}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('#${setIndex + 1}')),
          Expanded(
            child: TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Reps'),
              onSubmitted: (_) => _updateSet(
                  exIndex, setIndex, repsCtrl, weightCtrl, rpeCtrl),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: weightCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Gewicht'),
              onSubmitted: (_) => _updateSet(
                  exIndex, setIndex, repsCtrl, weightCtrl, rpeCtrl),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: rpeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(
                      decimal: true),
              decoration:
                  const InputDecoration(labelText: 'RPE'),
              onSubmitted: (_) => _updateSet(
                  exIndex, setIndex, repsCtrl, weightCtrl, rpeCtrl),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _removeSet(exIndex, setIndex);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateSet(
    int exIndex,
    int setIndex,
    TextEditingController reps,
    TextEditingController weight,
    TextEditingController rpe,
  ) async {
    final exs = (_data?['exercises'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (exIndex < 0 || exIndex >= exs.length) return;

    final ex = exs[exIndex];
    final sets = (ex['sets'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (setIndex < 0 || setIndex >= sets.length) return;

    final nr = int.tryParse(reps.text) ?? 0;
    final nw = double.tryParse(weight.text) ?? 0.0;
    final nRpe = double.tryParse(rpe.text) ?? 0.0;

    sets[setIndex] = {'reps': nr, 'weight': nw, 'rpe': nRpe};
    exs[exIndex] = {...ex, 'sets': sets};
    await _repo.updateExercise(
        widget.workoutId, exIndex, exs[exIndex]);

    if (mounted) setState(() {});

    final exId = (ex['id'] ?? '').toString();
    final exName = (ex['name'] ?? '').toString();
    await _pr.checkAndRecordPr(
      exerciseId: exId,
      exerciseName: exName,
      weight: nw,
      reps: nr,
    );
  }

  Future<void> _removeSet(int exIndex, int setIndex) async {
    final exs = (_data?['exercises'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (exIndex < 0 || exIndex >= exs.length) return;

    final ex = exs[exIndex];
    final sets = (ex['sets'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (setIndex < 0 || setIndex >= sets.length) return;

    final removed = sets.removeAt(setIndex);
    await _repo.updateExercise(
      widget.workoutId,
      exIndex,
      {...ex, 'sets': sets},
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Satz entfernt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () async {
            final undoSets =
                List<Map<String, dynamic>>.from(sets)
                  ..insert(setIndex, removed);
            await _repo.updateExercise(
              widget.workoutId,
              exIndex,
              {...ex, 'sets': undoSets},
            );
            if (mounted) setState(() {});
          },
        ),
      ),
    );

    setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
