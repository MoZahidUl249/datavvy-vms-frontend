/// Taka amounts: `৳ 1,29,000` uses Bangladeshi digit grouping (lakh / crore);
/// paisa are shown only when there are any (`৳ 4,500.50`).
String formatTaka(num amount) {
  final negative = amount < 0;
  final abs = amount.abs();
  final cents = (abs * 100).round();
  final whole = cents ~/ 100;
  final paisa = cents % 100;
  final digits = whole.toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final fraction = paisa == 0 ? '' : '.${paisa.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}৳ $grouped$fraction';
}
