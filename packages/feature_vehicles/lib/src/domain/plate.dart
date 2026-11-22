/// Bangladesh vehicle number split into the parts the plate input edits:
/// Area · [METRO] · Class · Series · Number → `DHA-METRO-GA 11-4582`.
///
/// Same rules as the backend (`VehicleNumber.java`); keep them in sync.
class PlateParts {
  const PlateParts({this.area = '', this.metro = false, this.cls = '', this.series = '', this.number = ''});

  static const empty = PlateParts();

  /// Areas whose plates normally carry METRO; the toggle auto-turns on for them.
  static const metroAreas = {'DHA', 'CTG', 'KHU', 'RAJ', 'SYL', 'BAR', 'RNG', 'MYM', 'GAZ', 'NAR', 'COM'};

  static final _loose = RegExp(r'^([A-Z]{3})(?:[\s-]*(METRO))?[\s-]*([A-Z]{1,3})[\s-]*(\d{2})[\s-]*(\d{4})$');

  final String area;
  final bool metro;
  final String cls;
  final String series;
  final String number;

  /// Parses any reasonable spelling ("dha metro ga 11 4582"); null if invalid.
  static PlateParts? tryParse(String raw) {
    final tidy = raw.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final m = _loose.firstMatch(tidy);
    if (m == null) return null;
    return PlateParts(
      area: m.group(1)!,
      metro: m.group(2) != null,
      cls: m.group(3)!,
      series: m.group(4)!,
      number: m.group(5)!,
    );
  }

  /// Parses or returns [empty] (for pre-filling the edit form).
  factory PlateParts.parse(String raw) => tryParse(raw) ?? empty;

  bool get isEmpty => area.isEmpty && cls.isEmpty && series.isEmpty && number.isEmpty;

  bool get isComplete => firstProblem == null;

  /// Canonical stored form, or '' when nothing is entered.
  String get value => isEmpty ? '' : '$area${metro ? '-METRO' : ''}-$cls $series-$number';

  /// Duplicate-comparison key (uppercase, no spaces/hyphens).
  static String key(String raw) => raw.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  /// First thing to fix, naming the part, with an example. Null when valid.
  String? get firstProblem {
    if (isEmpty) return 'Enter the vehicle number, like DHA-METRO-GA 11-4582.';
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(area)) return 'Area needs 3 letters, like DHA.';
    if (!RegExp(r'^[A-Z]{1,3}$').hasMatch(cls)) return 'Class needs 1–3 letters, like GA.';
    if (!RegExp(r'^\d{2}$').hasMatch(series)) return 'Series needs 2 digits, like 11.';
    if (!RegExp(r'^\d{4}$').hasMatch(number)) return 'Number needs 4 digits, like 4582.';
    return null;
  }

  PlateParts copyWith({String? area, bool? metro, String? cls, String? series, String? number}) => PlateParts(
        area: area ?? this.area,
        metro: metro ?? this.metro,
        cls: cls ?? this.cls,
        series: series ?? this.series,
        number: number ?? this.number,
      );

  @override
  bool operator ==(Object other) =>
      other is PlateParts &&
      other.area == area &&
      other.metro == metro &&
      other.cls == cls &&
      other.series == series &&
      other.number == number;

  @override
  int get hashCode => Object.hash(area, metro, cls, series, number);
}
