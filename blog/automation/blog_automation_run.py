#!/usr/bin/env python3
import json
from datetime import date
from pathlib import Path

BASE = Path('/home/admintest/.openclaw/workspace/aventurasvillas/blog')
CFG = json.loads((BASE/'automation/config.json').read_text())
QUEUE_PATH = BASE/'automation/topic_queue.json'
STATE_PATH = BASE/'automation/state.json'
queue = json.loads(QUEUE_PATH.read_text())
state = json.loads(STATE_PATH.read_text()) if STATE_PATH.exists() else {"last_index": -1}

if not queue:
    raise SystemExit('No topics in queue.')

next_idx = (state.get('last_index', -1) + 1) % len(queue)
topic = queue[next_idx]
hero = CFG['hero_images'][next_idx % len(CFG['hero_images'])]

today = date.today().isoformat()
slug = topic['slug']
draft_path = BASE / 'drafts' / f"{today}_{slug}.html"

html = f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>{topic['title']}</title>
  <link rel="stylesheet" href="../assets/parity.css" />
</head>
<body>
<header class="blog-nav"><div class="container blog-nav-inner"><div class="nav-logo">Aventuras Villas</div></div></header>
<section class="article-wrap">
  <article class="article">
    <div class="breadcrumb"><a href="../">← Back to Blog</a></div>
    <h1>{topic['title']}</h1>
    <div class="meta">Drafted {today} · Target 700–1200 words · Intent: {topic['search_intent']}</div>
    <div class="hero-media"><img src="{hero}" alt="{topic['title']}" /></div>

    <p><strong>Hook:</strong> This draft uses the Aventuras Villas warm-host voice and is optimized for conversion without sounding salesy.</p>

    <h2>Section outline (expand to full article)</h2>
    <ol>
      <li>Context + traveler pain point</li>
      <li>Decision framework for this topic</li>
      <li>Local/operational reality in Tulum</li>
      <li>Practical checklist guests can actually use</li>
      <li>Closing recommendation + booking path</li>
    </ol>

    <h2>Writing cues</h2>
    <ul>
      <li>Tone: warm, confident, practical, premium.</li>
      <li>No generic travel fluff.</li>
      <li>Use short paragraphs for mobile readability.</li>
      <li>End with clear next step.</li>
    </ul>

    <div class="cta">
      <strong>Find out more about Tulum & the Villas</strong>
      <div class="btns">
        <a class="btn btn-solid" href="{CFG['primary_cta']}">Book Direct</a>
        <a class="btn btn-linktree" href="{CFG['secondary_cta']}">Visit Linktree</a>
      </div>
    </div>
  </article>
</section>
</body>
</html>'''

draft_path.write_text(html)
state['last_index'] = next_idx
state['last_slug'] = slug
state['last_draft'] = str(draft_path)
STATE_PATH.write_text(json.dumps(state, indent=2))
print(json.dumps({"status":"ok","draft":str(draft_path),"topic":topic}, indent=2))
