import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';
import 'local_date.dart';

/// The current local date. Updates at local midnight and whenever the app
/// returns to the foreground (timers may not fire while the device sleeps).
class TodayNotifier extends Notifier<LocalDate> {
  Timer? _midnight;
  AppLifecycleListener? _lifecycle;

  @override
  LocalDate build() {
    final clock = ref.watch(clockProvider);
    _lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _midnight?.cancel();
      _lifecycle?.dispose();
    });
    final today = LocalDate.from(clock.now());
    _schedule(clock, today);
    return today;
  }

  void refresh() {
    final today = LocalDate.from(ref.read(clockProvider).now());
    if (today != state) state = today;
    _schedule(ref.read(clockProvider), today);
  }

  void _schedule(Clock clock, LocalDate today) {
    _midnight?.cancel();
    final wait = today.endOfDayLocal.difference(clock.now());
    _midnight = Timer(wait + const Duration(milliseconds: 250), refresh);
  }
}

final todayProvider = NotifierProvider<TodayNotifier, LocalDate>(
  TodayNotifier.new,
);
