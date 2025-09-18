import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable offline persistence & larger cache to speed up loads and ensure persistence.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (_) {
    // ignore if already set
  }

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
      title: 'Meine App',
      home: const AuthGate(), // sieh Schritt 7
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