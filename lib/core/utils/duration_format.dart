/// The live timer: `12:23` under an hour, `1:02:03` from the first hour on.
String formatTimer(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  String two(int v) => v.toString().padLeft(2, '0');
  final h = s ~/ 3600;
  final rest = '${two(s % 3600 ~/ 60)}:${two(s % 60)}';
  return h == 0 ? rest : '$h:$rest';
}

/// `HH:MM:SS`, hours zero-padded to at least two digits.
String formatHms(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
}

/// Short label for threshold lines: `5 min`, `25 min`, `1 h`, `1 h 30 min`.
String formatShortDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return '$h h';
  return '$h h $m min';
}

/// Spoken form for sentences: `25 minutes`, `1 hour`, `1 hour 30 minutes`.
String formatSpokenDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  String unit(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
  if (h == 0) return unit(m, 'minute');
  if (m == 0) return unit(h, 'hour');
  return '${unit(h, 'hour')} ${unit(m, 'minute')}';
}
