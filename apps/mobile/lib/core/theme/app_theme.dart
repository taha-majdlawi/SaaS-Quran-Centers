import 'package:flutter/material.dart';

import '../tenant/organization.dart';

/// Rebuilt every time the active organization changes (see main.dart's
/// _AppRouterHost, which watches TenantController) - `primary`/`secondary`
/// are pinned to the org's exact brand hex rather than left to
/// ColorScheme.fromSeed's tonal derivation, so a center's own colors show up
/// on every FilledButton/TextButton/AppBar exactly as its admin picked them
/// in settings_screen.dart, not an algorithmically-adjusted approximation.
ThemeData buildAppTheme(Organization? org) {
  final primary = org?.primaryColorValue ?? kDefaultBrandPrimary;
  final secondary = org?.secondaryColorValue ?? kDefaultBrandSecondary;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: secondary),
  );
}
