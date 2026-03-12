#!/usr/bin/env python3
import re
from pathlib import Path

BASE = Path('/home/admintest/.openclaw/workspace/aventurasvillas/blog')
issues = []
for p in sorted((BASE/'posts').glob('*.html')):
    txt = p.read_text()
    if 'https://linktr.ee/aventurasvillastulum' not in txt:
        issues.append(f"{p.name}: missing linktree CTA")
    if 'https://aventurasvillas.com' not in txt:
        issues.append(f"{p.name}: missing direct booking CTA")
    if '<div class="hero-media"><img' not in txt:
        issues.append(f"{p.name}: missing hero image")
    wc = len(re.findall(r'\b\w+\b', re.sub('<[^<]+?>', ' ', txt)))
    if wc < 320:
        issues.append(f"{p.name}: low word count ({wc})")

if issues:
    print('QA_FAIL')
    for i in issues:
        print('-', i)
else:
    print('QA_PASS')
