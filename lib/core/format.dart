/// Household number and time formats (docs/design.md §3).
library;

/// 2800 → "2 800". Thousands are separated by a space.
String spaced(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// 2800 → "2 800 ml".
String ml(int n) => '${spaced(n)} ml';

/// Minutes after midnight → "HH:mm", wrapping past midnight.
String hm(int minutes) {
  final m = minutes % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// 82 → "1 h 22 m"; 45 → "45 m".
String gap(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m m';
  if (m == 0) return '$h h';
  return '$h h $m m';
}

const _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "SAT 7 NOV".
String eyebrowDate(DateTime d) =>
    '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "Saturday, 7 November".
String proseDate(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}';

/// "Saturday".
String dayName(DateTime d) => _dayNames[d.weekday - 1];

/// One-letter weekday for chart axes.
String dayInitial(DateTime d) => _dayNames[d.weekday - 1][0];

/// "OCT".
String monthShort(DateTime d) => _months[d.month - 1];

const _words = [
  'naught', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', //
  'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
  'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty',
  'twenty-one', 'twenty-two',
];

/// 12 → "twelve". Falls back to digits beyond twenty-two.
String inWords(int n) => n >= 0 && n < _words.length ? _words[n] : '$n';

String capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
