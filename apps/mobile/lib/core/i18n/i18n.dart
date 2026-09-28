import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tenant/organization.dart';
import 'strings.dart';

export 'strings.dart';

/// The app's languages (docs/I18N.md). Only the student / guardian screens are
/// translated so far, so staff always get Arabic - [LocaleController.effective]
/// decides per signed-in role, like the web's "translated screens" list.
const kLocales = ['ar', 'en'];
const kLocaleNames = {'ar': 'العربية', 'en': 'English'};

/// The person's chosen language, remembered on the device.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final instance = LocaleController._();
  static const _key = 'app_lang';

  String _chosen = 'ar';
  String get chosen => _chosen;

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

  /// The language the app shows right now: the choice for students and
  /// guardians (their screens are translated), Arabic for everyone else.
  String effective(OrgRole? role) => role == OrgRole.student || role == OrgRole.guardian ? _chosen : 'ar';
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
