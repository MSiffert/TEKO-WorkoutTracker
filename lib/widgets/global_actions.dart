import 'package:flutter/material.dart';
import '../pages/dashboard_screen.dart';
import '../pages/exercise_catalog_screen.dart';
import '../pages/quick_log_screen.dart';
import '../pages/stats_screen.dart';

class GlobalActions {
  static List<Widget> actions(BuildContext context) => [
    IconButton(
      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen())),
      icon: const Icon(Icons.space_dashboard),
      tooltip: 'Dashboard',
    ),
    IconButton(
      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ExerciseCatalogScreen())),
      icon: const Icon(Icons.fitness_center),
      tooltip: 'Katalog',
    ),
    IconButton(
      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const QuickLogScreen())),
      icon: const Icon(Icons.bolt),
      tooltip: 'Quick Log',
    ),
    IconButton(
      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StatsScreen())),
      icon: const Icon(Icons.emoji_events),
      tooltip: 'PR & Stats',
    ),
  ];
}