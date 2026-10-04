#!/usr/bin/env python3
"""Copies the mushaf data (eqraa format) from a public base URL into the site.

    python3 tool/quran/import_quran_data.py https://<project>.supabase.co/storage/v1/object/public/quran

Reads   surah_1..114.json, audio/reciters.json, audio/timings/<reciter>/surah_<n>.json
Writes  apps/web/public/quran-data/...  (served by the site at /quran-data/...)
        apps/web/src/lib/quran/ayah-reciters.json  (the reciter list, built into the web app)

Each file is checked (114 surahs, 6236 ayahs, pages 1-604, timings shape) and
trimmed to the fields the readers use; nothing is written if the text is incomplete.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'apps', 'web', 'public', 'quran-data')
RECITERS_COPY = os.path.join(ROOT, 'apps', 'web', 'src', 'lib', 'quran', 'ayah-reciters.json')


def fetch(url, optional=False):
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'bustan-quran-import'}), timeout=60) as r:
                return json.loads(r.read().decode('utf-8-sig'))
        except urllib.error.HTTPError as e:
            if e.code in (400, 404) and optional:
                return None
            if attempt == 3:
                raise SystemExit(f'failed: {url} ({e.code})')
        except Exception as e:  # network hiccup
            if attempt == 3:
                raise SystemExit(f'failed: {url} ({e})')
        time.sleep(2 ** attempt)


def ar(v):
    return v if isinstance(v, str) else (v or {}).get('ar', '')


def write(rel, data):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))


def main():
    if len(sys.argv) != 2 or not sys.argv[1].startswith(('https://', 'http://127.0.0.1')):
        raise SystemExit(__doc__)
    base = sys.argv[1].rstrip('/')

    surahs, total = {}, 0
    for n in range(1, 115):
        raw = fetch(f'{base}/surah_{n}.json')
        verses = raw.get('verses') or []
        if not verses or len(verses) != raw.get('verses_count', len(verses)):
            raise SystemExit(f'surah {n}: verses missing or count mismatch')
        slim = {
            'number': n,
            'name': {'ar': ar(raw.get('name'))},
            'revelation_place': {'ar': ar(raw.get('revelation_place'))},
            'verses_count': len(verses),
            'verses': [],
            'audio': [
                {'reciter': {'ar': ar(a.get('reciter'))}, 'rewaya': {'ar': ar(a.get('rewaya'))}, 'link': a['link']}
                for a in raw.get('audio') or [] if isinstance(a.get('link'), str) and a['link'].startswith('https://')
            ],
        }
        for v in verses:
            page, juz = int(v['page']), int(v['juz'])
            if not (1 <= page <= 604 and 1 <= juz <= 30) or not ar(v.get('text')).strip():
                raise SystemExit(f'surah {n} ayah {v.get("number")}: bad page/juz/text')
            sajda = v.get('sajda')
            slim['verses'].append({
                'number': int(v['number']), 'text': {'ar': ar(v['text'])}, 'juz': juz, 'page': page,
                'sajda': {'obligatory': bool(sajda.get('obligatory'))} if isinstance(sajda, dict) else False,
            })
        surahs[n] = slim
        total += len(verses)
        print(f'surah {n}: {len(verses)} ayahs')
    if total != 6236:
        raise SystemExit(f'expected 6236 ayahs, got {total}')

    reciters = fetch(f'{base}/audio/reciters.json', optional=True) or []
    if isinstance(reciters, dict):  # {"reciters": [...]} is accepted too
        reciters = reciters.get('reciters') or []
    reciters = [
        {'id': str(r['id']), 'name_ar': r.get('name_ar') or str(r['id']), 'style_ar': r.get('style_ar') or '', 'base': r['base']}
        for r in reciters if r.get('id') is not None and str(r.get('base', '')).startswith('https://')
    ]
    print(f'{len(reciters)} ayah reciters')

    timings = {}
    for r in reciters:
        rid = r['id']
        for n in range(1, 115):
            t = fetch(f'{base}/audio/timings/{rid}/surah_{n}.json', optional=True)
            if t is None:
                continue
            ok = isinstance(t, dict) and all(
                isinstance(seg, list) and all(isinstance(s, list) and len(s) == 4 for s in seg) for seg in t.values()
            )
            if not ok:
                raise SystemExit(f'timings {rid}/{n}: unexpected shape')
            timings[(rid, n)] = t
        print(f'timings {rid}: {sum(1 for k in timings if k[0] == rid)}/114 surahs')

    # everything checked - replace the old copy
    if os.path.isdir(OUT):
        import shutil
        shutil.rmtree(OUT)
    for n, s in surahs.items():
        write(f'surah_{n}.json', s)
    write('audio/reciters.json', reciters)
    for (rid, n), t in timings.items():
        write(f'audio/timings/{rid}/surah_{n}.json', t)
    with open(RECITERS_COPY, 'w', encoding='utf-8') as f:
        json.dump(reciters, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print('done')


if __name__ == '__main__':
    main()
