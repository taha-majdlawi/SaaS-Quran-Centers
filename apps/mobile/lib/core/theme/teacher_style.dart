import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The look of the teacher's screens (modelled on the eqraa teacher app): a
/// cool light-grey page, white rounded cards with a hairline border, a gradient
/// header, gold accents and clear status colours. The BRAND colour is the
/// center's own (from its settings), so every center keeps its identity.
abstract final class TeacherStyle {
  // page + surfaces
  static const Color scaffold = kPageBackground;
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF8F6F0);
  static const Color chip = Color(0xFFF0EDE3);
  static const Color border = kHairline;
  static const Color textPrimary = kInk;
  static const Color textMuted = kInkMuted;

  // accents + status (semantic, not identity)
  static const Color gold = Color(0xFFC9982F);
  static const Color goldLight = Color(0xFFFAF3E2);
  static const Color success = Color(0xFF16835A);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFC0392B);
  static const Color blue = Color(0xFF1877C9);

  /// The center's colour, used for buttons and headers.
  static Color brand(BuildContext context) => Theme.of(context).colorScheme.primary;

  static LinearGradient headerGradient(BuildContext context) {
    final b = brand(context);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(b, Colors.black, 0.45)!, b],
    );
  }

  static Color tint(Color c, [double alpha = 0.10]) => c.withValues(alpha: alpha);

  /// A grade's colour from its rank among the center's grades (best first):
  /// green, blue, amber, then red - the centers name their grades differently.
  static Color gradeColor(List<dynamic> grades, String? key) {
    if (key == null) return textMuted;
    final sorted = [...grades]..sort((a, b) => (b.points as int).compareTo(a.points as int));
    final i = sorted.indexWhere((g) => g.key == key);
    return switch (i) { 0 => success, 1 => blue, 2 => warning, -1 => textMuted, _ => danger };
  }

  static const cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)), side: BorderSide(color: border));
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '؟';
  if (parts.length == 1) return parts.first.characters.first;
  return '${parts[0].characters.first}${parts[1].characters.first}';
}
