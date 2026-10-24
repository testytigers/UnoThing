import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/feature_flags.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../domain/models/goal.dart';
import '../../widgets/dock/morphing_dock.dart';
import '../../widgets/mascot/mascot.dart';
import '../../widgets/reminder_tile.dart';
import '../notifications/notification_scheduler.dart';
import '../notifications/reminder_planner.dart' show lastCallMinutes;
import '../notifications/reminders_controller.dart';

final _versionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// Settings (D5, grown with the reminders and Pro): reminders, the goals
/// (Pro), the Pro preview while testing, reset, and the app version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(
    BuildContext context, {
    required MascotMood mood,
    required String title,
    required String body,
    required String action,
  }) async {
    final t = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Mascot(mood: mood, size: 84),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: t.ink),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: t.dangerInk),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _reset(BuildContext context, WidgetRef ref, int count) async {
    final many = count > 1;
    final ok = await _confirm(
      context,
      mood: MascotMood.sad,
      title: many ? 'Reset everything?' : 'Reset goal?',
      body: many
          ? 'This deletes every goal and every logged day. It cannot be '
                'undone.'
          : 'This deletes your goal and every logged day. It cannot be '
                'undone.',
      action: 'Reset',
    );
    if (!ok) return;
    await ref.read(goalRepositoryProvider).resetAll();
    HapticFeedback.mediumImpact();
    if (context.mounted) context.go(Routes.login);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
    int count,
  ) async {
    final ok = await _confirm(
      context,
      mood: MascotMood.sad,
      title: 'Delete ${goal.title}?',
      body:
          'Its cups and every logged day go with it. It cannot be '
          'undone.',
      action: 'Delete',
    );
    if (!ok) return;
    await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
    HapticFeedback.mediumImpact();
    if (count == 1 && context.mounted) context.go(Routes.login);
  }

  /// Switching a reminder on needs notifications: ask in context.
  Future<void> _ensureNotifications(WidgetRef ref) =>
      ref.read(notificationsEnabledProvider.notifier).ensure();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final version = ref.watch(_versionProvider).value;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final prefs = ref.watch(appPreferencesProvider);
    final enabled = ref.watch(notificationsEnabledProvider);
    final exact = ref.watch(exactRemindersProvider);
    final anyReminder =
        prefs.lastCall || goals.any((g) => g.reminderMinutes != null);
    final repo = ref.read(preferencesRepositoryProvider);
    const gap = SizedBox(height: AppSpacing.sm);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.gutter,
                AppSpacing.gutter,
                MorphingDock.reserve + AppSpacing.md,
              ),
              children: [
                const _Heading('Reminders'),
                if (!enabled) ...[
                  _NotificationsOff(
                    onTurnOn: () async {
                      final granted = await ref
                          .read(notificationsEnabledProvider.notifier)
                          .ensure();
                      if (!granted) {
                        await ref
                            .read(notificationSchedulerProvider)
                            .openSettings();
                      }
                    },
                  ),
                  gap,
                ],
                for (final goal in goals) ...[
                  ReminderTile.daily(
                    context: context,
                    title: goal.title,
                    minutes: goal.reminderMinutes,
                    onChanged: (minutes) async {
                      await ref
                          .read(goalRepositoryProvider)
                          .setReminder(goal.id, minutes);
                      if (minutes != null) await _ensureNotifications(ref);
                    },
                  ),
                  gap,
                ],
                ReminderTile(
                  title: 'Last call',
                  subtitle:
                      'At ${formatMinutesOfDay(context, lastCallMinutes)}, '
                      "only if today isn't saved yet",
                  icon: Icons.nightlight_round,
                  value: prefs.lastCall,
                  onChanged: (on) async {
                    await repo.setBool(Pref.lastCall, on);
                    if (on) await _ensureNotifications(ref);
                  },
                ),
                gap,
                if (anyReminder) ...[
                  ReminderTile(
                    title: 'On-time reminders',
                    subtitle: exact
                        ? 'Reminders arrive on the minute'
                        : 'Allow "Alarms & reminders", or they may come up '
                              'to an hour late',
                    icon: Icons.schedule_rounded,
                    value: exact,
                    onChanged: (_) =>
                        ref.read(exactRemindersProvider.notifier).request(),
                  ),
                  gap,
                ],
                ReminderTile(
                  title: 'Milestones',
                  subtitle: 'Halfway, the final week and the last day',
                  icon: Icons.flag_rounded,
                  value: prefs.milestones,
                  onChanged: (on) async {
                    await repo.setBool(Pref.milestones, on);
                    if (on) await _ensureNotifications(ref);
                  },
                ),
                if (FeatureFlags.multiHabit) ...[
                  const _Heading('Pro preview'),
                  ReminderTile(
                    title: 'Pro preview',
                    subtitle:
                        'Testing only: unlocks up to 3 habits without '
                        'payment',
                    icon: Icons.auto_awesome,
                    value: prefs.proPreview,
                    onChanged: (on) => repo.setBool(Pref.proPreview, on),
                  ),
                ],
                if (goals.length > 1) ...[
                  const _Heading('Habits'),
                  for (final goal in goals) ...[
                    _Row(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete ${goal.title}',
                      color: t.dangerInk,
                      onTap: () => _delete(context, ref, goal, goals.length),
                    ),
                    gap,
                  ],
                ],
                const SizedBox(height: AppSpacing.lg),
                _Row(
                  icon: Icons.restart_alt_rounded,
                  label: goals.length > 1 ? 'Reset everything' : 'Reset goal',
                  color: t.dangerInk,
                  onTap: () => _reset(context, ref, goals.length),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Center(child: Mascot(mood: MascotMood.sleepy, size: 72)),
                const SizedBox(height: AppSpacing.sm),
                if (version != null)
                  Text(
                    'Version $version',
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: t.inkFaint),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, AppSpacing.md, 4, AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: AppText.eyebrow.copyWith(color: context.tokens.inkMuted),
        ),
      ),
    );
  }
}

/// A white row with an icon and a label, like a list button.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: AppSizes.tileHeight,
        leading: Icon(icon, color: color),
        title: Text(label, style: AppText.bodyStrong.copyWith(color: color)),
        onTap: onTap,
      ),
    );
  }
}

/// Shown when notifications are blocked: reminders can't arrive.
class _NotificationsOff extends StatelessWidget {
  const _NotificationsOff({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: t.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        children: [
          const Mascot(mood: MascotMood.sad, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Notifications are off, so reminders can't reach you.",
              style: AppText.label.copyWith(color: t.ink),
            ),
          ),
          TextButton(
            onPressed: onTurnOn,
            style: TextButton.styleFrom(
              foregroundColor: t.ink,
              minimumSize: const Size(48, 48),
            ),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
  }
}
