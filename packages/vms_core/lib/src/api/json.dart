/// Small helpers for reading decoded JSON safely.
library;

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<Object?> asList(Object? value) =>
    value is List ? value.cast<Object?>() : const <Object?>[];

int asInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

int? asIntOrNull(Object? value) => value is num ? value.toInt() : null;

String asString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

String? asStringOrNull(Object? value) => value is String ? value : null;

bool asBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

DateTime? asDateTime(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// Numbers that may arrive as int or decimal (money).
double asDouble(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : (value is String ? double.tryParse(value) ?? fallback : fallback);

/// Calendar day from `YYYY-MM-DD` (no time-zone shift), or null.
DateTime? asDate(Object? value) {
  if (value is! String || value.length < 10) return null;
  final d = DateTime.tryParse(value.substring(0, 10));
  return d == null ? null : DateTime(d.year, d.month, d.day);
}
