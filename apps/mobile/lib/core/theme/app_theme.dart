import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kDefaultBrandColor = Color(0xFF1E7A54);

/// Parses the organization's `#rrggbb` brand color, falling back to the
/// platform's own emerald if the value is missing or malformed.
Color parseBrandColor(String? hex) {
  if (hex == null) return kDefaultBrandColor;
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6) return kDefaultBrandColor;
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return kDefaultBrandColor;
  return Color(0xFF000000 | value);
}

/// The soft page + hairline palette every screen shares (also used by the teacher screens).
const kPageBackground = Color(0xFFF5F8FB);
const kHairline = Color(0xFFE7EDF3);
const kInk = Color(0xFF162434);
const kInkMuted = Color(0xFF64748B);

/// One Material 3 theme for the whole app, seeded from the active center's
/// brand color so every center feels like its own app while sharing the same
/// type (Tajawal), spacing, radii and component styles.
ThemeData buildAppTheme(Color seed) {
  final base = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  // the seed decides the identity; surfaces stay clean white instead of tinted
  final scheme = base.copyWith(primary: seed, onPrimary: ThemeData.estimateBrightnessForColor(seed) == Brightness.dark ? Colors.white : Colors.black, surface: Colors.white, surfaceTint: Colors.transparent);
  const radius = 14.0;

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  const family = 'Tajawal';
  final text = ThemeData(brightness: Brightness.light, fontFamily: family).textTheme.apply(bodyColor: kInk, displayColor: kInk);

  return ThemeData(
    useMaterial3: true,
    fontFamily: family,
    colorScheme: scheme,
    textTheme: text.copyWith(
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
    ),
    scaffoldBackgroundColor: kPageBackground,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(fontFamily: family, color: scheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kHairline)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: kInkMuted),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: border(Colors.grey.shade300),
      enabledBorder: border(const Color(0xFFD9E2EC)),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      disabledBorder: border(Colors.grey.shade200),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        textStyle: const TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        textStyle: const TextStyle(fontFamily: family, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
        textStyle: const TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: family, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: kInkMuted,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: kHairline),
      backgroundColor: const Color(0xFFEEF3F8),
      selectedColor: scheme.primary.withValues(alpha: 0.14),
      labelStyle: const TextStyle(fontFamily: family, fontWeight: FontWeight.w600),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : Colors.grey.shade50),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : Colors.grey.shade400),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: const Color(0xFFE3EAF1), circularTrackColor: Colors.transparent),
    dividerTheme: const DividerThemeData(color: kHairline, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kHairline)),
      textStyle: const TextStyle(fontFamily: family, color: kInk, fontSize: 14.5),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      contentTextStyle: const TextStyle(fontFamily: family, color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(fontFamily: family, color: kInk, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: kInk, borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontFamily: family, color: Colors.white, fontSize: 12),
    ),
  );
}
