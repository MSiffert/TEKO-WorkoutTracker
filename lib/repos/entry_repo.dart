import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

class EntryRepo {
  final String uid;
  EntryRepo(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('entries');

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRecent({int limitCount = 100}) {
    return _col.orderBy('createdAt', descending: true).limit(limitCount).snapshots();
  }

  Future<void> saveNote({required String title, required String desc}) async {
    final now = DateTime.now();
    await _col.add({
      'type': 'note',
      'title': title,
      'desc': desc,
      'sessionId': yyyymmdd(now),
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtStr': now.toIso8601String(),
    });
  }

  Future<void> saveLift({
    required String exerciseName,
    String? exerciseId,
    required List<Map<String, dynamic>> sets,
  }) async {
    final now = DateTime.now();
    await _col.add({
      'type': 'lift',
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'title': exerciseName,
      'desc': 'Quick log',
      'sessionId': yyyymmdd(now),
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtStr': now.toIso8601String(),
      'sets': sets,
    });
  }

  Future<Map<String, dynamic>?> read(String id) async {
    final d = await _col.doc(id).get();
    return d.data();
  }

  Future<void> restore(String id, Map<String, dynamic> data) async {
    await _col.doc(id).set(data);
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}