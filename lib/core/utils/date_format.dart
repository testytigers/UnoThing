import '../time/local_date.dart';

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _longMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `6 Dec`
String shortDate(LocalDate d) => '${d.day} ${_shortMonths[d.month - 1]}';

/// `6 December`
String longDate(LocalDate d) => '${d.day} ${_longMonths[d.month - 1]}';

/// `5-11 Dec`, or `29 Dec - 4 Jan` across months.
String weekRange(LocalDate monday) {
  final sunday = monday.addDays(6);
  if (monday.month == sunday.month) {
    return '${monday.day}-${sunday.day} ${_shortMonths[sunday.month - 1]}';
  }
  return '${shortDate(monday)} - ${shortDate(sunday)}';
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// `Wednesday 9 December`
String weekdayDate(LocalDate d) => '${_weekdays[d.weekday - 1]} ${longDate(d)}';
