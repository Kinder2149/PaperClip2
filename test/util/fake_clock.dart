import 'package:paperclip2/services/runtime/clock.dart';

class FakeClock implements Clock {
  DateTime _now;
  FakeClock(DateTime start) : _now = start;

  @override
  DateTime now() => _now;

  void advance(Duration d) {
    _now = _now.add(d);
  }
}
