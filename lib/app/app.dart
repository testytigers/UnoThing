import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dock/action_dock.dart';
import '../features/notifications/reminders_controller.dart';
import '../features/session/session_controller.dart';
import '../widgets/dock/morphing_dock.dart';
import '../widgets/mascot/mascot.dart';
import 'router.dart';
import 'routes.dart';
import 'theme.dart';

/// App-wide messenger, so toasts survive route changes (e.g. bank -> Shelf).
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// A short, floating confirmation, cheered by the mascot (happy by
/// default).
void showAppToast(String message, {MascotMood mood = MascotMood.happy}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        // Above the dock.
        margin: const EdgeInsets.fromLTRB(20, 0, 20, MorphingDock.reserve),
        padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
        content: Row(
          children: [
            Mascot(mood: mood, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

class TheOneThingApp extends ConsumerWidget {
  const TheOneThingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stop pressed on the pouring notification: show the paused session.
    ref.listen(stopRequestProvider, (_, _) {
      ref.read(routerProvider).go(Routes.sessionStop);
    });
    // Reminders follow the goals, today's cups and the switches.
    ref.watch(remindersControllerProvider);
    return MaterialApp.router(
      title: 'The One Thing',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
      // The dock floats above every page, so it can morph across navigation.
      builder: (context, child) =>
          Stack(children: [child!, const ActionDock()]),
    );
  }
}
