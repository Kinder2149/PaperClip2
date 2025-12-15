import 'package:intl/intl.dart';

class GameFormat {
  static const String _locale = 'fr_FR';

  static final NumberFormat _money2 = NumberFormat.currency(
    locale: _locale,
    symbol: '€',
    decimalDigits: 2,
  );

  static final NumberFormat _money1 = NumberFormat.currency(
    locale: _locale,
    symbol: '€',
    decimalDigits: 1,
  );

  static final NumberFormat _decimal1 = NumberFormat.decimalPattern(_locale)
    ..minimumFractionDigits = 1
    ..maximumFractionDigits = 1;

  static final NumberFormat _decimal0 = NumberFormat.decimalPattern(_locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 0;

  static final NumberFormat _int = NumberFormat.decimalPattern(_locale);

  static String money(double value, {int decimals = 2}) {
    if (decimals == 2) return _money2.format(value);
    if (decimals == 1) return _money1.format(value);

    final fmt = NumberFormat.currency(
      locale: _locale,
      symbol: '€',
      decimalDigits: decimals,
    );
    return fmt.format(value);
  }

  static String moneyPerMin(double value, {int decimals = 1}) {
    return '${money(value, decimals: decimals)}/min';
  }

  static String percentFromRatio(double ratio, {int decimals = 1}) {
    final pct = ratio * 100.0;
    final fmt = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return '${fmt.format(pct)}%';
  }

  static String intWithSeparators(int value) {
    return _int.format(value);
  }

  static String number(double value, {int decimals = 1}) {
    if (decimals == 1) return _decimal1.format(value);
    if (decimals == 0) return _decimal0.format(value);

    final fmt = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return fmt.format(value);
  }

  static String quantityCompact(num value, {int decimals = 1}) {
    final abs = value.abs().toDouble();
    if (abs < 1000) {
      if (value is int) return value.toString();
      return number(value.toDouble(), decimals: decimals);
    }

    final suffixes = <String>['K', 'M', 'B', 'T'];
    double scaled = value.toDouble();
    int suffixIndex = -1;

    while (scaled.abs() >= 1000 && suffixIndex < suffixes.length - 1) {
      scaled /= 1000;
      suffixIndex++;
    }

    final formatted = number(scaled, decimals: decimals);
    return '$formatted${suffixes[suffixIndex]}';
  }

  static String durationHms(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$hours:$mm:$ss';
  }
}
