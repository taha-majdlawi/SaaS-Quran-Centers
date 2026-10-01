# Writes l10n/<lang>/<group>.py from a JSON object on stdin:
#   {"group": {"tr": {key: value}, "fr": {key: value}}}
# (a helper for adding translations; the files are what gen.py reads)
import json, os, sys, pprint
HERE = os.path.dirname(os.path.abspath(__file__))
data = json.load(sys.stdin)
for group, langs in data.items():
    for lang, t in langs.items():
        d = os.path.join(HERE, 'l10n', lang); os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, f'{group}.py'), 'w', encoding='utf-8') as f:
            f.write(f'# {group} - {"Türkçe" if lang == "tr" else "Français"}. Same keys as the spec\'s English column.\n')
            f.write('T = ' + pprint.pformat(t, width=160, sort_dicts=False) + '\n')
        print('wrote', lang, group, len(t))
