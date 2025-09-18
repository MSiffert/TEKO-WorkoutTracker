
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../repos/exercise_repo.dart';
import '../repos/workout_repo.dart';
import '../services/pr_service.dart';
import '../services/progression_service.dart';
import '../utils/helpers.dart';

class QuickLogScreen extends StatefulWidget {
  const QuickLogScreen({super.key});

  @override
  State<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends State<QuickLogScreen> {
  final _exerciseCtrl = TextEditingController();
  final List<_SetRow> _sets = [ _SetRow() ];
  bool _saving = false;
  List<String> _exerciseNames = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = ExerciseRepo(uid);
    final names = await repo.listNamesOnce();
    setState(() { _exerciseNames = names; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Log')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue tev) {
              final txt = tev.text.trim();
              if (txt.isEmpty) return const Iterable<String>.empty();
              final low = txt.toLowerCase();
              return _exerciseNames.where((e) => e.toLowerCase().contains(low));
            },
            optionsViewBuilder: (context, onSelected, options) {
              final list = options.toList();
              return Material(
                elevation: 4,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: list.isEmpty ? 1 : list.length,
                  itemBuilder: (context, i) {
                    if (list.isEmpty) {
                      final text = _exerciseCtrl.text.trim();
                      return ListTile(
                        leading: const Icon(Icons.add),
                        title: Text('"' + text + '" anlegen'),
                        onTap: () => onSelected(text),
                      );
                    }
                    final val = list[i];
                    return ListTile(
                      title: Text(val),
                      onTap: () => onSelected(val),
                    );
                  },
                ),
              );
            },
            onSelected: (val) {
              _exerciseCtrl.text = val;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              _exerciseCtrl.value = textEditingController.value;
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Übungsname',
                  hintText: 'z. B. Bankdrücken',
                ),
                onChanged: (v) { _exerciseCtrl.text = v; },
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Sätze'),
          const SizedBox(height: 8),
          ..._sets.asMap().entries.map((e) => _setTile(e.key, e.value)),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _sets.add(_SetRow())),
                icon: const Icon(Icons.add),
                label: const Text('Satz hinzufügen'),
              ),
              const SizedBox(width: 12),
              if (_sets.length > 1)
                TextButton.icon(
                  onPressed: () => setState(() => _sets.removeLast()),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Letzten entfernen'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Speichere...' : 'Speichern'),
          )
        ],
      ),
    );
  }

  Widget _setTile(int idx, _SetRow s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
                onChanged: (v) => s.reps = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Gewicht (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => s.weight = double.tryParse(v) ?? 0.0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'RPE'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => s.rpe = double.tryParse(v) ?? 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _exerciseCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Übungsname fehlt')));
      return;
    }
    if (_sets.isEmpty || _sets.where((s) => s.reps > 0).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mindestens ein Satz mit Reps > 0')));
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final exRepo = ExerciseRepo(uid);
      final wRepo = WorkoutRepo(uid);
      await exRepo.createIfNotExists(name, 'Other');
      final key = normalizeName(name);
      final active = await wRepo.getOrStartActive(name: 'Workout');
      final wid = active.id;
      await wRepo.addExercise(wid, exerciseId: key, name: name);
      final setsList = _sets.map((s) => {'reps': s.reps, 'weight': s.weight, 'rpe': s.rpe}).toList();
      await wRepo.appendSets(wid, key, setsList);
      // PR check
      final pr = PRService(uid);
      double bestEst = 0.0; double bestW = 0.0; int bestR = 0;
      final ps = ProgressionService();
      for (final s in _sets) {
        final est = ps.estimate1RM(weight: s.weight, reps: s.reps);
        if (est > bestEst) { bestEst = est; bestW = s.weight; bestR = s.reps; }
      }
      if (bestEst > 0) await pr.checkAndRecordPr(exerciseId: key, exerciseName: name, weight: bestW, reps: bestR);
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gespeichert')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SetRow {
  int reps = 0;
  double weight = 0.0;
  double rpe = 0.0;
}