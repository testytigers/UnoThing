import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/constants.dart';

/// "7:00 PM" or "19:00", following the phone's 24-hour setting.
String formatMinutesOfDay(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Asks for a time of day; null if dismissed.
Future<int?> pickMinutesOfDay(
  BuildContext context, {
  required int initial,
  String helpText = 'Daily reminder',
}) async {
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    helpText: helpText,
  );
  return time == null ? null : time.hour * 60 + time.minute;
}

/// A white tile with a switch, for reminder settings. With [minutes] it
/// shows the time, and tapping the tile picks a new one.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon = Icons.notifications_active_outlined,
    this.onTap,
  });

  /// A daily reminder: on with its time, or off. Switching it on (or tapping
  /// the tile) asks for the time.
  factory ReminderTile.daily({
    Key? key,
    required BuildContext context,
    required String title,
    required int? minutes,
    required ValueChanged<int?> onChanged,
  }) {
    Future<void> pick() async {
      final picked = await pickMinutesOfDay(
        context,
        initial: minutes ?? defaultReminderMinutes,
      );
      if (picked != null) onChanged(picked);
    }

    return ReminderTile(
      key: key,
      title: title,
      subtitle: minutes == null
          ? 'Off'
          : 'Every pour day at ${formatMinutesOfDay(context, minutes)}',
      value: minutes != null,
      icon: Icons.alarm_rounded,
      onTap: pick,
      onChanged: (on) => on ? pick() : onChanged(null),
    );
  }

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  /// Tapping the tile; defaults to flipping the switch.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Its own Material, so the ripple shows on the white tile.
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      clipBehavior: Clip.antiAlias,
      // One node for screen readers: the title names the switch.
      child: MergeSemantics(
        child: ListTile(
          minTileHeight: AppSizes.tileHeight + 8,
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: t.brandInk),
          ),
          title: Text(title, style: AppText.bodyStrong.copyWith(color: t.ink)),
          subtitle: Text(
            subtitle,
            style: AppText.label.copyWith(
              color: t.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Switch(value: value, onChanged: onChanged),
          onTap: onTap ?? () => onChanged(!value),
        ),
      ),
    );
  }
}
