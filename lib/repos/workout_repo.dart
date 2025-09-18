import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

class WorkoutRepo {
  final String uid;
  WorkoutRepo(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workouts');

  Future<DocumentReference<Map<String, dynamic>>> startWorkout({
    required String name,
  }) async {
    final now = DateTime.now();
    final doc = await _col.add({
      'name': name,
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
      'startedAtClient': Timestamp.fromDate(now),
      'finishedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtClient': Timestamp.fromDate(now),
      'notes': '',
      'exercises': <Map<String, dynamic>>[],
    }).timeout(const Duration(seconds: 8));
    return doc;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getActiveToday() async {
    final today = DateTime.now();
    final dayStart = DateTime(today.year, today.month, today.day);

    final snap = await _col
        .where('status', isEqualTo: 'in_progress')
        .orderBy('startedAtClient', descending: true)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 8));

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final startedAtClient =
        (doc.data()['startedAtClient'] as Timestamp?)
                ?.toDate() ??
            dayStart;

    // Aktiv, wenn innerhalb letzter ~18h (z.B. gestriger Abend)
    if (startedAtClient.isAfter(dayStart.subtract(const Duration(hours: 6)))) {
      return doc;
    }
    return null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getOrStartActive({
    String? name,
  }) async {
    final active = await getActiveToday();
    if (active != null) return active;
    final docRef = await startWorkout(name: name ?? 'Workout');
    return await docRef.get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRecent({
    int limitCount = 50,
  }) {
    return _col
        .limit(limitCount)
        .snapshots();
  }

  Future<void> complete(String workoutId) async {
    await _col.doc(workoutId).update({
      'status': 'completed',
      'finishedAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 8));
  }

  Future<void> delete(String workoutId) async {
    await _col.doc(workoutId).delete().timeout(const Duration(seconds: 8));
  }

  Future<void> restore(String workoutId, Map<String, dynamic> data) async {
    await _col.doc(workoutId).set(data).timeout(const Duration(seconds: 8));
  }

  Future<void> rename(String id, String name) async {
    await _col.doc(id).update({'name': name}).timeout(const Duration(seconds: 8));
  }

  Future<Map<String, dynamic>?> read(String id) async {
    final d =
        await _col.doc(id).get().timeout(const Duration(seconds: 8));
    return d.data();
  }

  Future<void> addExercise(
    String workoutId, {
    required String exerciseId,
    required String name,
    int? order,
  }) async {
    final doc = await _col.doc(workoutId).get();
    final data = doc.data() ?? {};
    final List<dynamic> exs = (data['exercises'] as List?) ?? [];
    final existsIndex =
        exs.indexWhere((e) => (e['id'] ?? '') == exerciseId);
    if (existsIndex == -1) {
      final newEx = {
        'id': exerciseId,
        'name': name,
        'order': order ?? exs.length,
        'sets': <Map<String, dynamic>>[],
      };
      exs.add(newEx);
    } else {
      exs[existsIndex]['name'] = name;
    }
    await _col
        .doc(workoutId)
        .update({'exercises': exs}).timeout(const Duration(seconds: 8));
  }

  Future<void> appendSets(
    String workoutId,
    String exerciseId,
    List<Map<String, dynamic>> sets,
  ) async {
    return FirebaseFirestore.instance.runTransaction((txn) async {
      final docRef = _col.doc(workoutId);
      final snap = await txn.get(docRef);
      final data = snap.data() ?? {};
      final List<dynamic> exs = (data['exercises'] as List?) ?? [];
      final idx =
          exs.indexWhere((e) => (e['id'] ?? '') == exerciseId);
      if (idx == -1) {
        throw Exception('Exercise not in workout');
      }
      final List<dynamic> current =
          (exs[idx]['sets'] as List?) ?? [];
      current.addAll(sets);
      exs[idx]['sets'] = current;
      txn.update(docRef, {'exercises': exs});
    });
  }

  Future<void> updateExercise(
    String workoutId,
    int index,
    Map<String, dynamic> exercise,
  ) async {
    return FirebaseFirestore.instance.runTransaction((txn) async {
      final docRef = _col.doc(workoutId);
      final snap = await txn.get(docRef);
      final data = snap.data() ?? {};
      final List<dynamic> exs = (data['exercises'] as List?) ?? [];
      if (index < 0 || index >= exs.length) return;
      exs[index] = exercise;
      txn.update(docRef, {'exercises': exs});
    });
  }

  Future<void> removeExercise(String workoutId, int index) async {
    return FirebaseFirestore.instance.runTransaction((txn) async {
      final docRef = _col.doc(workoutId);
      final snap = await txn.get(docRef);
      final data = snap.data() ?? {};
      final List<dynamic> exs = (data['exercises'] as List?) ?? [];
      if (index < 0 || index >= exs.length) return;
      exs.removeAt(index);
      txn.update(docRef, {'exercises': exs});
    });
  }

  /// Insertiert eine Übung an einer bestimmten Position (für Undo).
  Future<void> insertExerciseAt(
    String workoutId,
    int index,
    Map<String, dynamic> exercise,
  ) async {
    return FirebaseFirestore.instance.runTransaction((txn) async {
      final docRef = _col.doc(workoutId);
      final snap = await txn.get(docRef);
      final data = snap.data() ?? {};
      final List<dynamic> exs = (data['exercises'] as List?) ?? [];
      final safeIndex = index.clamp(0, exs.length);
      exs.insert(safeIndex, exercise);
      txn.update(docRef, {'exercises': exs});
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> stream(
    String id, {
    bool includeMetadataChanges = true,
  }) {
    return _col
        .doc(id)
        .snapshots(includeMetadataChanges: includeMetadataChanges);
  }
}
