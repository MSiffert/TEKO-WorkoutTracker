import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditWorkoutScreen extends StatefulWidget {
  final String workoutId;
  const EditWorkoutScreen({super.key, required this.workoutId});

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  final List<_ExerciseInput> _exercises = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(widget.workoutId);

    final snap = await ref.get();
    final data = snap.data();
    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout nicht gefunden.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    _titleCtrl.text = (data['title'] ?? '').toString();
    _descCtrl.text  = (data['description'] ?? '').toString();

    final exercises = ((data['exercises'] ?? []) as List).cast<Map<String, dynamic>>();
    for (final ex in exercises) {
      final exInput = _ExerciseInput();
      exInput.nameCtrl.text = (ex['name'] ?? '').toString();
      final sets = ((ex['sets'] ?? []) as List).cast<Map<String, dynamic>>();
      for (final s in sets) {
        final setInput = _SetInput();
        setInput.repsCtrl.text = ((s['reps'] ?? 0)).toString();
        final w = s['weight'];
        setInput.weightCtrl.text = (w is num ? w.toDouble() : 0.0).toString();
        exInput.sets.add(setInput);
      }
      _exercises.add(exInput);
    }

    if (mounted) setState(() => _loading = false);
  }

  void _addExercise() {
    setState(() => _exercises.add(_ExerciseInput()));
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_exercises.isEmpty || _exercises.any((e) => e.sets.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens eine Übung mit mindestens einem Satz hinzufügen.')),
      );
      return;
    }

    setState(() => _saving = true);

    final exercises = _exercises.map((e) {
      final sets = e.sets.map((s) {
        final reps = int.tryParse(s.repsCtrl.text.trim());
        final weight = double.tryParse(s.weightCtrl.text.trim().replaceAll(',', '.'));
        return {
          'reps': reps ?? 0,
          'weight': weight ?? 0.0,
        };
      }).toList();

      return {
        'name': e.nameCtrl.text.trim(),
        'sets': sets,
      };
    }).toList();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(widget.workoutId);

    await ref.set({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'exercises': exercises,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout bearbeiten'),
        actions: [
          IconButton(
            tooltip: 'Speichern',
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titel'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Titel angeben' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Ergebnis / Notizen'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Übungen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Übung hinzufügen'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_exercises.isEmpty)
              const Text('Noch keine Übungen.'),

            ..._exercises.asMap().entries.map((entry) {
              final idx = entry.key;
              final exercise = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: TextFormField(
                    controller: exercise.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Übungsname',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Übungsnamen angeben' : null,
                  ),
                  trailing: IconButton(
                    tooltip: 'Übung entfernen',
                    onPressed: () => _removeExercise(idx),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  children: [
                    if (exercise.sets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Text('Noch keine Saetze.'),
                      ),
                    ...exercise.sets.asMap().entries.map((sEntry) {
                      final sIdx = sEntry.key;
                      final set = sEntry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: set.repsCtrl,
                                decoration: const InputDecoration(labelText: 'Wdh.'),
                                keyboardType: TextInputType.number,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: set.weightCtrl,
                                decoration: const InputDecoration(labelText: 'Gewicht (kg)'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Satz entfernen',
                              onPressed: () => setState(() => exercise.sets.removeAt(sIdx)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => exercise.sets.add(_SetInput())),
                          icon: const Icon(Icons.add),
                          label: const Text('Satz hinzufügen'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Speichere...' : 'Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseInput {
  final TextEditingController nameCtrl = TextEditingController();
  final List<_SetInput> sets = [];
  void dispose() {
    nameCtrl.dispose();
    for (final s in sets) {
      s.dispose();
    }
  }
}

class _SetInput {
  final TextEditingController repsCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
}
