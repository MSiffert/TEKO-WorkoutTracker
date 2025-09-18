
class ProgressionService {
  double suggestNextWeight({
    required double lastWeight,
    required int lastTopReps,
    int targetReps = 8,
    double increment = 2.5,
  }) {
    if (lastTopReps >= targetReps) {
      return _roundToIncrement(lastWeight + increment, increment);
    }
    return lastWeight;
  }

  double estimate1RM({required double weight, required int reps}) {
    return weight * (1 + reps / 30.0);
  }

  double estimate1RMBrzycki({required double weight, required int reps}) {
    return weight * 36 / (37 - reps);
  }

  double _roundToIncrement(double value, double step) {
    return (value / step).roundToDouble() * step;
  }
}