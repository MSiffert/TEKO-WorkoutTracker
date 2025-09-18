
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'progression_service.dart';

class PRService {
  final String uid;
  PRService(this.uid);

  CollectionReference<Map<String, dynamic>> get _bestCol =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('pr_best');
  CollectionReference<Map<String, dynamic>> get _eventsCol =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('pr_events');

  final _ps = ProgressionService();

  Future<void> checkAndRecordPr({
    required String exerciseId,
    required String exerciseName,
    required double weight,
    required int reps,
  }) async {
    final est = _ps.estimate1RM(weight: weight, reps: reps);
    final bestDoc = _bestCol.doc(exerciseId);
    final snap = await bestDoc.get().timeout(const Duration(seconds: 8));
    final prev = (snap.data()?['best1rm'] as num?)?.toDouble() ?? 0.0;
    if (est > prev + 0.01) {
      final now = DateTime.now();
      await bestDoc.set({'exerciseId': exerciseId, 'exerciseName': exerciseName, 'best1rm': est});
      await _eventsCol.add({
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'estimated1RM': est,
        'weight': weight,
        'reps': reps,
        'at': FieldValue.serverTimestamp(),
        'atClient': Timestamp.fromDate(now),
      });
    }
  }
}