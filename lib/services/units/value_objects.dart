class Seconds {
  final double value;

  const Seconds(this.value);

  bool get isFinitePositive => value.isFinite && value > 0;

  Minutes toMinutes() => Minutes(value / 60.0);
}

class Minutes {
  final double value;

  const Minutes(this.value);

  Seconds toSeconds() => Seconds(value * 60.0);
}

class Money {
  final double value;

  const Money(this.value);

  Money operator +(Money other) => Money(value + other.value);
  Money operator -(Money other) => Money(value - other.value);
  Money operator *(double factor) => Money(value * factor);
}

class Units {
  final double value;

  const Units(this.value);

  int floorToInt() => value.floor();

  Units operator +(Units other) => Units(value + other.value);
  Units operator -(Units other) => Units(value - other.value);
  Units operator *(double factor) => Units(value * factor);
}

class UnitsPerSecond {
  final double value;

  const UnitsPerSecond(this.value);

  Units over(Seconds seconds) => Units(value * seconds.value);
  UnitsPerMinute toPerMinute() => UnitsPerMinute(value * 60.0);
}

class UnitsPerMinute {
  final double value;

  const UnitsPerMinute(this.value);

  UnitsPerSecond toPerSecond() => UnitsPerSecond(value / 60.0);
}

class Ratio {
  final double value;

  const Ratio(this.value);

  Ratio clamp01() {
    final v = value < 0 ? 0.0 : (value > 1 ? 1.0 : value);
    return Ratio(v);
  }

  double toPercent() => value * 100.0;
}
