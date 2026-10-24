import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../../core/constants.dart';
import '../../core/time/clock.dart';
import '../../core/time/local_date.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/active_session.dart';
import '../../domain/models/goal.dart';
import '../../domain/services/timer_engine.dart';
import 'background/pour_notification.dart';
import 'background/pour_service.dart';

/// The session restored at launch (after midnight reconciliation).
/// Overridden in `main`.
final initialSessionProvider = Provider<ActiveSession?>((ref) => null);

/// Fired once when a running day crosses the safety net. Overridable in tests.
final safetyNetAlertProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await HapticFeedback.heavyImpact();
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: [0, 140, 90, 260]);
      }
    } on Object catch (e) {
      debugPrint('Vibration unavailable: $e');
    }
  },
);

/// One frame of the stopwatch: the persisted session and the instant it is
/// rendered at.
@immutable
class SessionState {
  const SessionState(this.session, this.now);

  final ActiveSession? session;
  final DateTime now;

  /// Current stopwatch value, or null with no session.
  int? get value => session?.valueAt(now);

  bool get isRunning => session?.isRunning ?? false;
}

/// One-shot request for the Shelf to animate a cup rising (Frame 10).
@immutable
class FillAnimation {
  const FillAnimation({
    required this.goalId,
    required this.date,
    required this.fromSeconds,
    required this.id,
  });

  final int goalId;
  final LocalDate date;
  final int fromSeconds;
  final int id;
}

class FillAnimationNotifier extends Notifier<FillAnimation?> {
  int _next = 0;

  @override
  FillAnimation? build() => null;

  void trigger(int goalId, LocalDate date, int fromSeconds) =>
      state = FillAnimation(
        goalId: goalId,
        date: date,
        fromSeconds: fromSeconds,
        id: ++_next,
      );
}

final fillAnimationProvider =
    NotifierProvider<FillAnimationNotifier, FillAnimation?>(
      FillAnimationNotifier.new,
    );

/// Bumped when Stop is pressed on the notification; the app shows Frame 11.
class StopRequestNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final stopRequestProvider = NotifierProvider<StopRequestNotifier, int>(
  StopRequestNotifier.new,
);

class SessionController extends Notifier<SessionState> {
  Timer? _ticker;
  AppLifecycleListener? _lifecycle;

  Clock get _clock => ref.read(clockProvider);
  TimerEngine get _engine => ref.read(timerEngineProvider);

  @override
  SessionState build() {
    _lifecycle = AppLifecycleListener(onResume: reconcile);
    ref.onDispose(() {
      _ticker?.cancel();
      _lifecycle?.dispose();
    });
    _pour.listen(_onServiceMessage);
    final initial = ref.read(initialSessionProvider);
    final s = SessionState(initial, _clock.now());
    _scheduleTick(s);
    // A session restored at launch gets its notification back.
    if (initial != null) Future.microtask(() => _startService(initial));
    return s;
  }

  PourService get _pour => ref.read(pourServiceProvider);

  Future<void> _startService(ActiveSession session) async {
    final goal = await ref.read(goalRepositoryProvider).getGoal(session.goalId);
    if (goal == null) return;
    await _pour.ensurePermission();
    await _pour.start(
      goalTitle: goal.title,
      seconds: session.valueAt(_clock.now()),
    );
  }

  void _onServiceMessage(String message) {
    unawaited(reload());
    if (message == PourMessage.stop) {
      ref.read(stopRequestProvider.notifier).request();
    }
  }

  /// Re-reads the session the service may have changed (pause from the
  /// notification, safety net, midnight).
  Future<void> reload() async => _set(await _engine.current());

  void _set(ActiveSession? session) {
    final next = SessionState(session, _clock.now());
    state = next;
    _scheduleTick(next);
  }

  /// Ticks only while running, aligned to whole elapsed seconds so the
  /// display never skips or repeats a digit. Display only: the value always
  /// comes from timestamps.
  void _scheduleTick(SessionState s) {
    _ticker?.cancel();
    final session = s.session;
    if (session == null || !session.isRunning) return;
    final elapsedMs = s.now
        .difference(session.segmentStartedAt!)
        .inMilliseconds;
    final wait = 1000 - (elapsedMs % 1000) + 8;
    _ticker = Timer(Duration(milliseconds: wait), _tick);
  }

  Future<void> _tick() async {
    var session = state.session;
    if (session == null) return;
    final now = _clock.now();
    if (LocalDate.from(now) != session.date) {
      await reconcile();
      return;
    }
    if (_pour.isActive) {
      // The service owns the alerts; pick up its changes.
      session = await _engine.current();
    } else if (session.isRunning) {
      final value = session.valueAt(now);
      if (!session.safetyNetFired && value >= safetyNetSeconds) {
        session = await _engine.markSafetyNetFired(session);
        unawaited(ref.read(safetyNetAlertProvider)());
      }
      // In the app the cup itself celebrates a full cup; just remember it.
      if (!session.targetFired) {
        final goal = await ref
            .read(goalRepositoryProvider)
            .getGoal(session.goalId);
        if (goal != null && value >= goal.dailyTargetSeconds) {
          session = await _engine.markTargetFired(session);
        }
      }
    }
    _set(session);
  }

  /// Applies midnight rollover (and stale paused sessions) to the stored
  /// session.
  Future<void> reconcile() async {
    final session = await _engine.reconcile();
    _set(session);
    if (session == null) await _pour.stop();
  }

  /// Starts pouring into [goal] on [date]. Does nothing while any session
  /// is active: one goal pours at a time.
  Future<void> start(Goal goal, LocalDate date) async {
    final existing = state.session;
    if (existing != null) return;
    final session = await _engine.start(goal, date);
    _set(session);
    await _startService(session);
  }

  Future<void> pause() async {
    final s = state.session;
    if (s != null) _set(await _engine.pause(s));
  }

  Future<void> resume() async {
    final s = state.session;
    if (s != null) _set(await _engine.resume(s));
  }

  /// Banks and asks the Shelf to animate the cup rising (Frame 10).
  Future<void> bank() async {
    final s = state.session;
    if (s == null) return;
    final goal = await ref.read(goalRepositoryProvider).getGoal(s.goalId);
    if (goal == null) return;
    await _engine.bank(s, goal);
    ref
        .read(fillAnimationProvider.notifier)
        .trigger(goal.id, s.date, s.baseSeconds);
    _set(null);
    await _pour.stop();
  }

  Future<void> discard() async {
    await _engine.discard();
    _set(null);
    await _pour.stop();
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

/// The goal the active session pours into, or null with no session.
final sessionGoalProvider = Provider<Goal?>((ref) {
  final id = ref.watch(
    sessionControllerProvider.select((s) => s.session?.goalId),
  );
  if (id == null) return null;
  final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
  return goals.where((g) => g.id == id).firstOrNull;
});
