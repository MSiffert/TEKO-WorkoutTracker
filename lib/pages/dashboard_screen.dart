
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final workoutsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('workouts');
    final prEventsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('pr_events');

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: workoutsCol.where('startedAtClient', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo)).get(),
            builder: (context, snap) {
              final points = List<double>.filled(7, 0.0);
              final nowDay = DateTime(now.year, now.month, now.day);
              for (final d in snap.data?.docs ?? []) {
                final data = d.data();
                final ts = data['startedAtClient'] as Timestamp?; final dt = ts?.toDate() ?? now;
                final delta = nowDay.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
                final idx = (6 - delta).clamp(0, 6);
                final exs = (data['exercises'] as List?) ?? const [];
                final sets = <Map<String, dynamic>>[];
                for (final e in exs) { sets.addAll(((e['sets'] as List?) ?? const []).cast<Map<String, dynamic>>()); }
                double vol = 0.0;
                for (final s in sets) {
                  final reps = (s['reps'] as num?)?.toInt() ?? 0;
                  final weight = (s['weight'] as num?)?.toDouble() ?? 0.0;
                  vol += reps * weight;
                }
                points[idx] += vol;
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Wochenvolumen (kg·Reps)'),
                      const SizedBox(height: 8),
                      Sparkline(points: points),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: prEventsCol.orderBy('atClient', descending: true).limit(5).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(title: Text('Letzte PRs')),
                    const Divider(height: 1),
                    ...docs.map((d){
                      final e = d.data();
                      final ex = (e['exerciseName'] ?? e['exerciseId'] ?? '').toString();
                      final oneRm = (e['estimated1RM'] as num?)?.toDouble() ?? 0.0;
                      final w = (e['weight'] as num?)?.toDouble() ?? 0.0;
                      final r = (e['reps'] as num?)?.toInt() ?? 0;
                      return ListTile(
                        title: Text(ex),
                        subtitle: Text('1RM ~ ${oneRm.toStringAsFixed(1)} kg • ${w.toStringAsFixed(1)} x$r'),
                      );
                    }).toList()
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('PR & Stats ansehen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
          )
        ],
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  final List<double> points;
  const Sparkline({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _SparkPainter(points),
        child: Container(),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  _SparkPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final maxV = points.reduce((a,b) => a > b ? a : b);
    final minV = points.reduce((a,b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final yNorm = (points[i] - minV) / range;
      final y = size.height - yNorm * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) => oldDelegate.points != points;
}