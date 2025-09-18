
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

class ExerciseRepo {
  final String uid;
  ExerciseRepo(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises');

  Future<List<String>> listNamesOnce() async {
    final q = await _col.get();
    return q.docs.map((d) => (d['name'] as String)).toList();
  }

  Future<bool> existsByKey(String name) async {
    final key = normalizeName(name);
    final doc = await _col.doc(key).get();
    return doc.exists;
  }

  Future<void> createIfNotExists(String name, String category) async {
    final key = normalizeName(name);
    final doc = _col.doc(key);
    final snap = await doc.get();
    if (snap.exists) return;
    await doc.set({
      'id': key,
      'name': name,
      'nameKey': key,
      'nameLower': name.toLowerCase(),
      'category': category,
      'tags': <String>[]
    });
  }

  Future<void> updateNameAndCategory({required String id, required String name, required String category}) async {
    await _col.doc(id).update({'name': name, 'nameLower': name.toLowerCase(), 'category': category});
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}