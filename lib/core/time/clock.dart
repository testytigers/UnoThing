import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now". Inject this anywhere time matters so tests can control
/// the current instant and midnight.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock whose time only moves when told to. For tests.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void set(DateTime value) => _now = value;

  void advance(Duration by) => _now = _now.add(by);
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
