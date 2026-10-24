import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/constants.dart';
import '../core/time/local_date.dart';
import '../core/time/today.dart';
import '../data/repositories/daily_log_repository.dart';
import '../domain/models/goal.dart';
import 'primary_button.dart';

/// Opens the Adjust time sheet (Edit Log in the spec) for [date]. Only today and past days inside the
/// horizon may be edited.
Future<void> showEditLogSheet(
  BuildContext context, {
  required Goal goal,
  required LocalDate date,
  required int currentSeconds,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        EditLogSheet(goal: goal, date: date, currentSeconds: currentSeconds),
  );
}

class EditLogSheet extends ConsumerStatefulWidget {
  const EditLogSheet({
    super.key,
    required this.goal,
    required this.date,
    required this.currentSeconds,
  });

  final Goal goal;
  final LocalDate date;
  final int currentSeconds;

  @override
  ConsumerState<EditLogSheet> createState() => _EditLogSheetState();
}

class _EditLogSheetState extends ConsumerState<EditLogSheet> {
  late final _minutes = TextEditingController(
    text: '${widget.currentSeconds ~/ 60}',
  );
  late final _seconds = TextEditingController(
    text: '${widget.currentSeconds % 60}',
  );
  bool _saving = false;

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  int? get _total {
    final m = int.tryParse(_minutes.text.isEmpty ? '0' : _minutes.text);
    final s = int.tryParse(_seconds.text.isEmpty ? '0' : _seconds.text);
    if (m == null || s == null || m < 0 || s < 0 || s > 59) return null;
    final total = m * 60 + s;
    return total > maxLoggableSeconds ? null : total;
  }

  String? get _error {
    final s = int.tryParse(_seconds.text.isEmpty ? '0' : _seconds.text);
    if (s != null && s > 59) return 'Seconds must be between 0 and 59.';
    if (_total == null) return 'A day can hold at most 24 hours.';
    return null;
  }

  Future<void> _save() async {
    final total = _total;
    final goal = widget.goal;
    if (total == null) return;
    final today = ref.read(todayProvider);
    assert(!widget.date.isAfter(today) && goal.contains(widget.date));
    setState(() => _saving = true);
    await ref
        .read(dailyLogRepositoryProvider)
        .setTotal(goal, widget.date, total, today);
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final error = _error;

    Widget field(TextEditingController c, String unit, String label) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.label.copyWith(color: t.inkMuted)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: c,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                textAlign: TextAlign.center,
                style: AppText.timer.copyWith(color: t.ink, fontSize: 32),
                cursorColor: t.brand,
                decoration: InputDecoration(
                  suffixText: unit,
                  suffixStyle: AppText.bodyStrong.copyWith(color: t.inkMuted),
                ),
                onChanged: (_) => setState(() {}),
                onTap: () => c.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: c.text.length,
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Adjust time', style: AppText.headline.copyWith(color: t.ink)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                field(_minutes, 'min', 'Minutes'),
                const SizedBox(width: AppSpacing.md),
                field(_seconds, 'sec', 'Seconds'),
              ],
            ),
            AnimatedSize(
              duration: AppDurations.fast,
              child: error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        error,
                        style: AppText.label.copyWith(color: t.dangerInk),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Save',
              busy: _saving,
              onPressed: error == null ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
