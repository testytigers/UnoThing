import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/time/local_date.dart';
import '../features/auth/frame_01_login.dart';
import '../features/day_detail/day_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/horizon/frame_15_horizon.dart';
import '../features/onboarding/frame_02_goal.dart';
import '../features/onboarding/frame_03_horizon.dart';
import '../features/onboarding/frame_04_daily_target.dart';
import '../features/onboarding/frame_05_days.dart';
import '../features/onboarding/frame_06_contract.dart';
import '../features/session/frame_08_active_session.dart';
import '../features/session/frame_11_session_stop.dart';
import '../features/session/frame_12_banked_today.dart';
import '../features/settings/settings_screen.dart';
import '../features/shelf/frame_07_shelf.dart';
import 'routes.dart';
import 'theme.dart';

/// Where the app opens. Overridden in `main` after reading the database:
/// a restored session, else Home if a goal exists, else Login.
final startupLocationProvider = Provider<String>((ref) => Routes.login);

/// The root navigator: dialogs and sheets opened from the dock (which sits
/// above the pages) use its context.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Counts dialogs and sheets on screen; the dock steps aside for them.
class PopupRouteObserver extends NavigatorObserver {
  final open = ValueNotifier<int>(0);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) open.value++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) open.value--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) open.value--;
  }
}

final popupRouteObserverProvider = Provider<PopupRouteObserver>((ref) {
  final observer = PopupRouteObserver();
  ref.onDispose(observer.open.dispose);
  return observer;
});

/// The current path, e.g. `/home/habit/session`, kept in step with the
/// router (the dock follows it).
class LocationNotifier extends Notifier<String> {
  @override
  String build() {
    final router = ref.watch(routerProvider);
    final delegate = router.routerDelegate;
    void update() {
      final path = delegate.currentConfiguration.uri.path;
      if (ref.mounted && path.isNotEmpty && path != state) state = path;
    }

    void listener() => Future.microtask(update);
    delegate.addListener(listener);
    ref.onDispose(() => delegate.removeListener(listener));
    final path = delegate.currentConfiguration.uri.path;
    return path.isEmpty ? ref.read(startupLocationProvider) : path;
  }
}

final locationProvider = NotifierProvider<LocationNotifier, String>(
  LocationNotifier.new,
);

/// Session frames swap in place with a cross-fade: the cup and timer stay put
/// while the controls change.
Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: AppDurations.medium,
  reverseTransitionDuration: AppDurations.medium,
  transitionsBuilder: (_, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  ),
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: ref.read(startupLocationProvider),
    observers: [ref.read(popupRouteObserverProvider)],
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.goal, builder: (_, _) => const GoalScreen()),
      GoRoute(
        path: Routes.horizonStep,
        builder: (_, _) => const HorizonStepScreen(),
      ),
      GoRoute(
        path: Routes.targetStep,
        builder: (_, _) => const DailyTargetScreen(),
      ),
      GoRoute(path: Routes.daysStep, builder: (_, _) => const DaysScreen()),
      GoRoute(path: Routes.contract, builder: (_, _) => const ContractScreen()),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: 'habit',
            builder: (_, _) => const ShelfScreen(),
            routes: [
              GoRoute(
                path: 'horizon',
                builder: (_, _) => const HorizonScreen(),
              ),
              GoRoute(
                path: 'session',
                pageBuilder: (_, state) =>
                    _fade(state, const ActiveSessionScreen()),
              ),
              GoRoute(
                path: 'stop',
                pageBuilder: (_, state) =>
                    _fade(state, const SessionStopScreen()),
              ),
              GoRoute(
                path: 'today',
                builder: (_, _) => const BankedTodayScreen(),
              ),
              GoRoute(
                path: 'day/:date',
                builder: (_, state) => DayDetailScreen(
                  date: LocalDate.parse(state.pathParameters['date']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
