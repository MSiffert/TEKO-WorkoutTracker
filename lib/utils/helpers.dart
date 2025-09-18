
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String normalizeName(String s) {
  var t = s.trim().toLowerCase();
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  t = t.replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue');
  t = t.replaceAll('ß', 'ss');
  return t;
}

String yyyymmdd(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final da = d.day.toString().padLeft(2, '0');
  return '$y$m$da';
}

DateTime readCreatedAt(Map<String, dynamic> d) {
  final ts = d['createdAt'];
  if (ts is Timestamp) return ts.toDate();
  final s = d['createdAtStr'] as String? ?? '';
  return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

int parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse('$v') ?? 0.0;
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
