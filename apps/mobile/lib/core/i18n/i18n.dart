import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

export 'strings.dart';

/// The app's languages (docs/I18N.md). Every screen is translated; the
/// Quran text, surah headers and certificate wording stay Arabic by design.
const kLocales = ['ar', 'en'];
const kLocaleNames = {'ar': 'العربية', 'en': 'English'};

/// The app language: the person's own choice (remembered on the device), else
/// their center's default language (organization_settings.default_language),
/// else Arabic - the same order as the web.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final instance = LocaleController._();
  static const _key = 'app_lang';

  String? _chosen;
  String? _centerDefault;
  String? _centerOrg;
  String? _loginDefault;

  /// The language showing right now.
  String get effective => _chosen ?? _centerDefault ?? _loginDefault ?? 'ar';

  /// Whether the person picked a language themselves (else the center's default applies).
  bool get hasChoice => _chosen != null;

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      if (saved != null && kLocales.contains(saved)) _chosen = saved;
    } catch (_) {}
  }

  Future<void> choose(String lang) async {
    if (!kLocales.contains(lang) || lang == _chosen) return;
    _chosen = lang;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_key, lang);
    } catch (_) {}
  }

  /// Before sign-in: the center typed on the login screen may have a default
  /// language (get_public_site) - use it until the person signs in or picks one.
  void setLoginDefault(String? lang) {
    final v = lang != null && kLocales.contains(lang) ? lang : null;
    if (v == _loginDefault) return;
    final before = effective;
    _loginDefault = v;
    if (effective != before) notifyListeners();
  }

  /// Follow the signed-in center's default language; [fetch] reads it (null = none set).
  Future<void> bindCenter(String? orgId, Future<String?> Function(String orgId) fetch) async {
    if (orgId == _centerOrg) return;
    _centerOrg = orgId;
    final before = effective;
    _centerDefault = null;
    if (orgId != null) {
      try {
        final v = await fetch(orgId);
        if (orgId == _centerOrg && kLocales.contains(v)) _centerDefault = v;
      } catch (_) {}
    }
    if (effective != before) notifyListeners();
  }
}

/// Carries the current strings down the tree; [S.of] reads it (and rebuilds on change).
class StringsScope extends InheritedWidget {
  const StringsScope({super.key, required this.strings, required super.child});

  final S strings;

  @override
  bool updateShouldNotify(StringsScope oldWidget) => oldWidget.strings.lang != strings.lang;
}

/// Strings for code without a BuildContext (formatters, error text). Kept in
/// step with the mounted [StringsScope] by the app shell.
S currentStrings = S.ar;

/// The strings for [context]: `tr(context).portal.hello`. Rebuilds the caller
/// when the language changes (falls back to [currentStrings] without a scope).
S tr(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StringsScope>()?.strings ?? currentStrings;

/// "{name} is here" + {'name': 'x'} -> "x is here".
String fmt(String template, Map<String, Object?> vars) =>
    template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => vars.containsKey(m[1]) ? '${vars[m[1]]}' : m[0]!);
