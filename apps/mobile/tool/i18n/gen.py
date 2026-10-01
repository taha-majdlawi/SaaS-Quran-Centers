# Generates lib/core/i18n/strings.dart from the spec_*.py files next to this one.
#   python3 tool/i18n/gen.py        (from apps/mobile)
# Each spec row is (key, arabic, english): a string, a list or a map; placeholders
# like {name} are filled in Dart with fmt(). A language missing a key, a list of a
# different length or a map with other keys fails here - and the Dart class makes a
# missing field a compile error too. See docs/I18N.md.
import glob, importlib.util, os, json
HERE = os.path.dirname(__file__)
SPEC = {}
for f in sorted(glob.glob(os.path.join(HERE, 'spec_*.py')), key=lambda f: (not f.endswith('spec_base.py'), f)):
    s = importlib.util.spec_from_file_location(os.path.basename(f)[:-3], f); m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
    for k, v in m.SPEC.items():
        assert k not in SPEC, k
        SPEC[k] = v

# Turkish and French: l10n/<lang>/<group>.py, each `T = {key: value}` with the
# same keys and shapes as the English column. A missing key fails the build.
import re
EXTRA = ('tr', 'fr')
L10N = {}
for lang in EXTRA:
    L10N[lang] = {}
    for f in sorted(glob.glob(os.path.join(HERE, 'l10n', lang, '*.py'))):
        s = importlib.util.spec_from_file_location(f'{lang}_' + os.path.basename(f)[:-3], f); m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
        L10N[lang][os.path.basename(f)[:-3]] = m.T
_problems = []
_flat = lambda x: ' '.join(x.values()) if isinstance(x, dict) else ' '.join(x) if isinstance(x, list) else x
for lang in EXTRA:
    for name, (doc, rows) in SPEC.items():
        t = L10N[lang].get(name)
        if t is None:
            _problems.append(f'{lang}: group {name} missing'); continue
        keys = {r[0] for r in rows}
        for k in keys - set(t): _problems.append(f'{lang}.{name}.{k} missing')
        for k in set(t) - keys: _problems.append(f'{lang}.{name}.{k} is not in the spec')
        for key, ar, en in rows:
            if key not in t: continue
            v = t[key]
            if type(v) != type(en): _problems.append(f'{lang}.{name}.{key}: wrong type'); continue
            if isinstance(en, dict) and set(v) != set(en): _problems.append(f'{lang}.{name}.{key}: map keys differ')
            if isinstance(en, list) and len(v) != len(en): _problems.append(f'{lang}.{name}.{key}: list length differs')
            if set(re.findall(r'\{(\w+)\}', _flat(en))) != set(re.findall(r'\{(\w+)\}', _flat(v))):
                _problems.append(f'{lang}.{name}.{key}: placeholders differ')
if _problems:
    raise SystemExit('translations incomplete:\n  ' + '\n  '.join(_problems[:60]) + (f'\n  ... {len(_problems) - 60} more' if len(_problems) > 60 else ''))

DART_KEYWORDS = {'new', 'default', 'class', 'is', 'in', 'as', 'if', 'do', 'for', 'switch', 'case', 'return', 'this', 'super', 'null', 'true', 'false', 'var', 'const', 'final', 'void', 'with', 'extends', 'try', 'catch', 'throw', 'enum', 'assert', 'break', 'continue', 'else', 'while', 'rethrow'}

def lit(v):
    if isinstance(v, str):
        return "'" + v.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n') + "'"
    if isinstance(v, list):
        return '[' + ', '.join(lit(x) for x in v) + ']'
    if isinstance(v, dict):
        return '{' + ', '.join(f'{lit(k)}: {lit(x)}' for k, x in v.items()) + '}'
    raise TypeError(v)

def typ(v):
    return 'String' if isinstance(v, str) else 'List<String>' if isinstance(v, list) else 'Map<String, String>'

def cls(name): return 'S' + name[0].upper() + name[1:]

out = ['// GENERATED from the i18n spec (see docs/I18N.md) - edit the spec, not this file.',
       '// Every language must fill every field: a missing translation is a compile error.',
       '// ignore_for_file: lines_longer_than_80_chars', '']
for name, (doc, rows) in SPEC.items():
    for key, ar, en in rows:
        assert key not in DART_KEYWORDS, f'{name}.{key} is a Dart keyword'
        assert type(ar) == type(en), (name, key)
        if isinstance(ar, dict): assert set(ar) == set(en), (name, key)
        if isinstance(ar, list): assert len(ar) == len(en), (name, key)
    out.append(f'/// {doc}')
    out.append(f'class {cls(name)} {{')
    out.append(f'  const {cls(name)}({{' + ', '.join(f'required this.{k}' for k, _, _ in rows) + '});')
    for k, ar, _ in rows:
        out.append(f'  final {typ(ar)} {k};')
    out.append('}')
    out.append('')

out.append('class S {')
out.append('  const S({required this.lang, ' + ', '.join(f'required this.{n}' for n in SPEC) + '});')
out.append("  /// 'ar', 'en', 'tr' or 'fr'.")
out.append('  final String lang;')
out.append("  bool get isAr => lang == 'ar';")
for n in SPEC:
    out.append(f'  final {cls(n)} {n};')
out.append('')
for li, lang in ((1, 'ar'), (2, 'en'), ('tr', 'tr'), ('fr', 'fr')):
    out.append(f"  static const {lang} = S(")
    out.append(f"    lang: '{lang}',")
    for n, (doc, rows) in SPEC.items():
        out.append(f'    {n}: {cls(n)}(')
        for row in rows:
            out.append(f'      {row[0]}: {lit(L10N[li][n][row[0]] if isinstance(li, str) else row[li])},')
        out.append('    ),')
    out.append('  );')
    out.append('')
out.append('}')
open(os.path.join(HERE, '..', '..', 'lib', 'core', 'i18n', 'strings.dart'), 'w').write('\n'.join(out) + '\n')
print('generated', sum(len(r) for _, r in SPEC.values()), 'strings in', len(SPEC), 'groups')
