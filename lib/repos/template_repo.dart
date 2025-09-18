import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateRepo {
  final String uid;
  TemplateRepo(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('workout_templates');

  static List<Map<String, dynamic>> defaults = [
    {
      'id': 'push',
      'name': 'Push',
      'exercises': [
        {'id': 'bankdruecken_langhantel', 'name': 'Bankdrücken Langhantel', 'sets': [{'reps': 8, 'weight': 0.0, 'rpe': 7.5}]},
        {'id': 'schulterdruecken_kurzhantel', 'name': 'Schulterdrücken Kurzhantel', 'sets': [{'reps': 10, 'weight': 0.0, 'rpe': 7.5}]},
        {'id': 'dips', 'name': 'Dips', 'sets': [{'reps': 8, 'weight': 0.0, 'rpe': 7.5}]},
      ]
    },
    {
      'id': 'pull',
      'name': 'Pull',
      'exercises': [
        {'id': 'klimmzuege', 'name': 'Klimmzüge', 'sets': [{'reps': 6, 'weight': 0.0, 'rpe': 8.0}]},
        {'id': 'rudern_kabel', 'name': 'Rudern Kabel', 'sets': [{'reps': 10, 'weight': 0.0, 'rpe': 7.5}]},
        {'id': 'face_pulls', 'name': 'Face Pulls', 'sets': [{'reps': 12, 'weight': 0.0, 'rpe': 7.0}]},
      ]
    },
    {
      'id': 'legs',
      'name': 'Legs',
      'exercises': [
        {'id': 'kniebeugen', 'name': 'Kniebeugen', 'sets': [{'reps': 5, 'weight': 0.0, 'rpe': 8.0}]},
        {'id': 'beinpresse', 'name': 'Beinpresse', 'sets': [{'reps': 10, 'weight': 0.0, 'rpe': 7.5}]},
        {'id': 'hip_thrust', 'name': 'Hip Thrust', 'sets': [{'reps': 8, 'weight': 0.0, 'rpe': 7.5}]},
      ]
    },
    {
      'id': 'full_body',
      'name': 'Full Body',
      'exercises': [
        {'id': 'kniebeugen', 'name': 'Kniebeugen', 'sets': [{'reps': 5, 'weight': 0.0, 'rpe': 8.0}]},
        {'id': 'bankdruecken_langhantel', 'name': 'Bankdrücken Langhantel', 'sets': [{'reps': 8, 'weight': 0.0, 'rpe': 7.5}]},
        {'id': 'rudern_kabel', 'name': 'Rudern Kabel', 'sets': [{'reps': 10, 'weight': 0.0, 'rpe': 7.5}]},
      ]
    }
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCustom() => _col.orderBy('name').snapshots();
  Future<void> saveCustomTemplate({required String id, required String name, required List<Map<String, dynamic>> exercises}) async {
    await _col.doc(id).set({'id': id, 'name': name, 'exercises': exercises});
  }
  Future<void> deleteCustom(String id) => _col.doc(id).delete();
}