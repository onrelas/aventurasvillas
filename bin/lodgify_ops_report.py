#!/usr/bin/env python3
import json
import requests
from datetime import date, datetime, timedelta
from pathlib import Path
from collections import Counter, defaultdict

BASE = Path('/home/admintest/.openclaw/workspace/aventurasvillas')
REPORT_DIR = BASE / 'reports'
REPORT_DIR.mkdir(parents=True, exist_ok=True)
TODAY = date.today().isoformat()

# Load API key
api_key = None
for line in Path('/home/admintest/.openclaw/scripts/lodgify_env.sh').read_text().splitlines():
    if 'LODGIFY_API_KEY' in line and '=' in line:
        api_key = line.split('=', 1)[1].strip().strip('"')
        break
if not api_key:
    raise SystemExit('Missing LODGIFY_API_KEY in lodgify_env.sh')

headers = {'X-ApiKey': api_key, 'accept': 'application/json'}
props = requests.get('https://api.lodgify.com/v1/properties', headers=headers, timeout=60)
resv = requests.get('https://api.lodgify.com/v1/reservation', headers=headers, timeout=60)
props.raise_for_status()
resv.raise_for_status()

properties = props.json() if isinstance(props.json(), list) else props.json().get('items', [])
reservations = resv.json().get('items', [])

prop_names = {p.get('id'): p.get('name') for p in properties}

# Normalize records
records = []
for r in reservations:
    arr = r.get('arrival')
    dep = r.get('departure')
    try:
        arr_d = datetime.fromisoformat(arr).date() if arr else None
        dep_d = datetime.fromisoformat(dep).date() if dep else None
    except Exception:
        arr_d = dep_d = None

    nights = (dep_d - arr_d).days if arr_d and dep_d else 0
    total = float(r.get('total_amount') or 0)
    adr = (total / nights) if nights > 0 and total > 0 else None
    pid = r.get('property_id')
    pname = r.get('property_name') or prop_names.get(pid) or f'Property {pid}'

    records.append({
        'id': r.get('id'),
        'property_id': pid,
        'property_name': pname,
        'status': r.get('status'),
        'source': r.get('source_text') or r.get('source') or 'Unknown',
        'arrival': arr,
        'departure': dep,
        'arrival_date': arr_d,
        'departure_date': dep_d,
        'nights': nights,
        'total_amount': total,
        'currency': r.get('currency') or 'USD',
        'adr': adr,
        'created_at': r.get('created_at')
    })

# Ops metrics
status_counts = Counter([x['status'] or 'Unknown' for x in records])
source_counts = Counter([x['source'] for x in records])
prop_counts = Counter([x['property_name'] for x in records])

# Upcoming 60-day occupancy (estimated from reservations)
start = date.today()
end = start + timedelta(days=60)
occupied_nights = defaultdict(int)
total_nights_window = defaultdict(int)
for p in prop_counts.keys():
    total_nights_window[p] = (end - start).days

for x in records:
    if not x['arrival_date'] or not x['departure_date']:
        continue
    cur = max(x['arrival_date'], start)
    stop = min(x['departure_date'], end)
    while cur < stop:
        occupied_nights[x['property_name']] += 1
        cur += timedelta(days=1)

occ = {}
for p in total_nights_window:
    total_n = total_nights_window[p]
    occ[p] = round((occupied_nights[p] / total_n) * 100, 1) if total_n else 0

# Pricing action suggestions (very simple rules)
pricing_actions = []
for p in total_nights_window:
    pct = occ.get(p, 0)
    if pct < 25:
        action = 'LOW pickup: consider -8% to -12% on next 21 days + 2-night min stay.'
    elif pct < 45:
        action = 'MED pickup: test -4% to -6% on weekdays only.'
    elif pct > 75:
        action = 'HIGH pickup: consider +5% to +10% on high-demand dates.'
    else:
        action = 'STABLE pickup: keep base rates, optimize channel mix and direct booking CTA.'
    pricing_actions.append({'property': p, 'occupancy_next_60d_pct': pct, 'action': action})

# ADR by property
adr_by_property = defaultdict(list)
for x in records:
    if x['adr']:
        adr_by_property[x['property_name']].append(x['adr'])
avg_adr = {p: round(sum(v)/len(v), 2) for p, v in adr_by_property.items() if v}

ops_payload = {
    'date': TODAY,
    'properties_count': len(properties),
    'reservations_count': len(records),
    'status_breakdown': dict(status_counts),
    'source_breakdown': dict(source_counts),
    'reservation_breakdown_by_property': dict(prop_counts),
    'avg_adr_by_property': avg_adr,
    'occupancy_next_60d_pct_by_property': occ,
    'pricing_actions': pricing_actions,
}

ops_json = REPORT_DIR / f'{TODAY}_lodgify_ops.json'
ops_txt = REPORT_DIR / f'{TODAY}_lodgify_ops.txt'
ops_json.write_text(json.dumps(ops_payload, indent=2))

lines = [
    f'Aventuras Villas Lodgify Ops Report ({TODAY})',
    f'Properties: {len(properties)} | Reservations: {len(records)}',
    '',
    'Status breakdown:'
]
for k,v in status_counts.items():
    lines.append(f'- {k}: {v}')
lines.append('')
lines.append('By property:')
for k,v in prop_counts.items():
    lines.append(f'- {k}: {v} reservations')
lines.append('')
lines.append('Average ADR (historical):')
if avg_adr:
    for k,v in avg_adr.items():
        lines.append(f'- {k}: {v}')
else:
    lines.append('- No ADR values available from API payload.')
lines.append('')
lines.append('Occupancy next 60 days (estimated):')
for p,v in occ.items():
    lines.append(f'- {p}: {v}%')
lines.append('')
lines.append('Pricing actions:')
for a in pricing_actions:
    lines.append(f"- {a['property']}: {a['action']}")

ops_txt.write_text('\n'.join(lines) + '\n')

print(json.dumps({'status':'ok','ops_json':str(ops_json),'ops_txt':str(ops_txt),'summary':ops_payload}, indent=2))
