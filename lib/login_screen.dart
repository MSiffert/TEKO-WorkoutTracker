import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Registrieren')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-Mail')),
          TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Passwort'), obscureText: true),
          const SizedBox(height: 12),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isLogin) {
                  await signInWithEmail(emailCtrl.text.trim(), passCtrl.text.trim());
                } else {
                  await registerWithEmail(emailCtrl.text.trim(), passCtrl.text.trim());
                }
              } on Exception catch (e) {
                setState(() => error = e.toString());
              }
            },
            child: Text(isLogin ? 'Einloggen' : 'Account erstellen'),
          ),
          TextButton(
            onPressed: () => setState(() => isLogin = !isLogin),
            child: Text(isLogin ? 'Noch kein Account? Registrieren' : 'Schon ein Account? Login'),
          ),
        ]),
      ),
    );
  }
}