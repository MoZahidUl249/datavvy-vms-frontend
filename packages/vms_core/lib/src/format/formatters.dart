/// Locale-free formatting used across features (no intl dependency yet).
library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// `19 Nov 2026`
String formatDate(DateTime? d) =>
    d == null ? '—' : '${d.day} ${_months[d.month - 1]} ${d.year}';

/// `November 2026`
String formatMonth(DateTime d) => '${_monthsLong[d.month - 1]} ${d.year}';

/// `2026-11-19` (API date parameter)
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Midnight of the same calendar day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
