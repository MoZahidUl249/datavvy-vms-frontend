import 'package:material_ui/material_ui.dart';

/// Colour roles from `references/tokens.css`. Use the role, not the hex.
abstract final class VmsColors {
  static const nav = Color(0xFF1F4E79);
  static const primary = Color(0xFF5B9BD5);
  static const primaryAccessible = Color(0xFF2E75B6);
  static const page = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF8FAFC);
  static const text = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF4B5563);
  static const textMeta = Color(0xFF6B7280);
  static const label = Color(0xFF374151);
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const successText = Color(0xFF166534);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerText = Color(0xFF991B1B);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFEF3C7);
  static const warningText = Color(0xFF92400E);
  static const infoBg = Color(0xFFEAF2FA);
  static const selectedBg = Color(0xFFF0F7FD);
  static const borderInput = Color(0xFFD5DCE5);
  static const borderCard = Color(0xFFE8ECF2);
  static const borderPlate = Color(0xFFC9D3DF);
  static const divider = Color(0xFFEEF2F6);
  static const track = Color(0xFFEEF2F7);
  static const switchOff = Color(0xFFCBD5E1);
  static const focusRing = Color(0x8C5B9BD5);

  /// Series colours for charts (navy first, then brand blue …).
  static const chart = [
    Color(0xFF1F4E79),
    Color(0xFF5B9BD5),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF94A3B8),
  ];
}

/// 8 pt spacing grid.
abstract final class VmsSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
}

abstract final class VmsRadius {
  static const plate = 6.0;
  static const small = 8.0;
  static const control = 10.0;
  static const group = 12.0;
  static const card = 14.0;
  static const dialog = 16.0;
  static const pill = 999.0;
}

abstract final class VmsSize {
  static const control = 44.0;
  static const controlSmall = 36.0;
  static const row = 68.0;
  static const sidebar = 240.0;
  static const contentList = 1180.0;
  static const contentForm = 880.0;
}

/// Type scale (skill §2).
abstract final class VmsText {
  static const _tabular = [FontFeature.tabularFigures()];

  static const title = TextStyle(
    fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, letterSpacing: -0.56, color: VmsColors.text);
  static const h2 = TextStyle(
    fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, letterSpacing: -0.17, color: VmsColors.text);
  static const section = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: VmsColors.text);
  static const body = TextStyle(fontSize: 15, height: 22 / 15, color: VmsColors.text);
  static const table = TextStyle(fontSize: 14, color: VmsColors.text);
  static const meta = TextStyle(fontSize: 13, height: 18 / 13, color: VmsColors.textMeta);
  static const secondary = TextStyle(fontSize: 13, height: 18 / 13, color: VmsColors.textSecondary);
  static const label = TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600, color: VmsColors.label);
  static const th = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VmsColors.textMeta, letterSpacing: 0.2);
  static const kpi = TextStyle(
    fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, color: VmsColors.text, fontFeatures: _tabular);

  /// For plates, counts, dates.
  static TextStyle tabular(TextStyle base) => base.copyWith(fontFeatures: _tabular);
}

abstract final class VmsShadows {
  static const popover = [BoxShadow(color: Color(0x2E101828), blurRadius: 44, offset: Offset(0, 20))];
  static const dialog = [BoxShadow(color: Color(0x38101828), blurRadius: 48, offset: Offset(0, 24))];
  static const segment = [BoxShadow(color: Color(0x1A101828), blurRadius: 3, offset: Offset(0, 1))];
}
