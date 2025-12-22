class BackoffPolicy {
  // Délais exponentiels bornés (minutes): 1, 5, 30, 120, 240
  static const List<Duration> steps = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
    Duration(hours: 2),
    Duration(hours: 4),
  ];

  static Duration nextDelay(int attempts) {
    if (attempts <= 0) return steps.first;
    final idx = attempts >= steps.length ? steps.length - 1 : attempts;
    return steps[idx];
  }
}
