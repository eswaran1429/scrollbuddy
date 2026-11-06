const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// e.g. "Mon 3 Nov".
String shortDate(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// e.g. "M".
String weekdayLetter(DateTime d) => _weekdays[d.weekday - 1][0];

/// e.g. "09:05".
String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Watch time, e.g. "0m", "<1m", "12m", "1h 05m".
String watchTime(int seconds) {
  if (seconds <= 0) return '0m';
  if (seconds < 60) return '<1m';
  final m = seconds ~/ 60;
  return m < 60 ? '${m}m' : '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
}
