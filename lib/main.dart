import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Tracker',
      home: const AuthGate(),
    );
  }
}

Future<UserCredential> registerWithEmail(String email, String password) async {
  final cred = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(email: email, password: password);
  return cred;
}

Future<UserCredential> signInWithEmail(String email, String password) async {
  final cred = await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: email, password: password);
  return cred;
}

Future<void> signOut() => FirebaseAuth.instance.signOut();
