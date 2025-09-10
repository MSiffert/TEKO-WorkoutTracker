import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_entry_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Stream der Eintraege des aktuellen Users
  Stream<QuerySnapshot<Map<String, dynamic>>> _entriesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _deleteEntry(String docId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('entries')
        .doc(docId)
        .delete();
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Eintraege'),
        actions: [
          IconButton(
            tooltip: 'Ausloggen',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _entriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Fehler: ${snapshot.error}'),
            );
          }
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Hallo ${user.email ?? user.uid}\nNoch keine Eintraege.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddEntryScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Neues Workout...'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] ?? '').toString();
              final subtitle = (data['description'] ?? '').toString();

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Löschen bestaetigen'),
                      content: const Text('Diesen Eintrag wirklich löschen?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                      ],
                    ),
                  ) ??
                      false;
                },
                onDismissed: (_) => _deleteEntry(doc.id),
                child: ListTile(
                  title: Text(title.isEmpty ? '(Ohne Titel)' : title),
                  subtitle: Text(subtitle.isEmpty ? 'Kein Text' : subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Löschen bestaetigen'),
                          content: const Text('Diesen Eintrag wirklich löschen?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
                          ],
                        ),
                      ) ?? false;

                      if (ok) {
                        await _deleteEntry(doc.id);
                      }
                    },
                  ),
                  onTap: () {
                    // Hier koenntest du eine Detailseite oeffnen
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEntryScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
      ),
    );
  }
}
