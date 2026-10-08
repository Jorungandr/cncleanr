"""Build Decimal gold values from downloaded government snapshots (stdlib only)."""
import csv
import hashlib
import json
import re
import xml.etree.ElementTree as ET
from collections import Counter
from decimal import Decimal
from pathlib import Path

root = Path('outputs/broad-data-audit')
rows = []
numeric = re.compile(r'[+-]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?(?:[eE][+-]?\d+)?')

def load(name):
    return json.loads((root / name).read_text(encoding='utf-8-sig'), parse_float=Decimal)

def add(source, row, field, value, unit='', scale=1):
    raw = '' if value is None else str(value)
    text = raw.strip()
    status = 'numeric' if numeric.fullmatch(text) else ('missing' if text in ('', '-') else 'review')
    expected = str(Decimal(text.replace(',', '')) * scale) if status == 'numeric' else ''
    rows.append([source, row, field, raw, unit, status, expected, '', 'raw'])

wb = load('worldbank.json')
assert wb[0]['pages'] == 1 and len(wb[1]) == wb[0]['total']
for i, record in enumerate(wb[1], 1):
    add('WDI:' + record['indicator']['id'], i, record['date'] + ':' + record['countryiso3code'], record['value'])
for i, record in enumerate(ET.parse(root / 'tw-education.xml').getroot(), 1):
    for field in record:
        if field.tag.endswith(('_千人', '_百分比')):
            add('TW:education', i, field.tag, field.text, field.tag.rsplit('_', 1)[1])
for i, record in enumerate(load('tw-air.json'), 1):
    for field in ('aqi so2 co o3 o3_8hr pm10 pm2.5 no2 nox no wind_speed wind_direc co_8hr pm2.5_avg pm10_avg so2_avg').split():
        add('TW:air', i, field, record[field], 'source-specific; see metadata')
for i, record in enumerate(load('tw-jobs.json'), 1):
    fields = {k.split('（')[0]: v for k, v in record.items()}
    for field in ('JOB_PERSON', 'NT_L', 'NT_U'):
        add('TW:jobs', i, field, fields[field], fields['SALARYCD'] if field != 'JOB_PERSON' else 'persons')
    if not all(numeric.fullmatch(fields[k].strip()) for k in ('NT_L', 'NT_U')):
        continue
    lo, hi = (Decimal(fields[k].strip().replace(',', '')) for k in ('NT_L', 'NT_U'))
    # Only a lexical interval check: zero/open-ended salaries are not closed ranges.
    if 0 < lo <= hi:
        rows.append(['TW:jobs', i, 'salary_interval', f'{lo}~{hi}', fields['SALARYCD'], 'range', str(lo), str(hi), 'derived'])
with (root / 'tw-tourism.csv').open(encoding='utf-8-sig', newline='') as handle:
    for i, record in enumerate(csv.DictReader(handle), 1):
        for field, value in record.items():
            if '人次' in field or '萬元' in field:
                add('TW:tourism', i, field.strip(), value, '萬元' if '萬元' in field else 'persons', 10000 if '萬元' in field else 1)
with (root / 'cases.tsv').open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t')
    writer.writerow(['source', 'row', 'field', 'input', 'unit', 'status', 'expected', 'upper', 'kind'])
    writer.writerows(rows)
print(Counter((r[0], r[5], r[8]) for r in rows))
for path in sorted(root.iterdir()):
    if path.suffix in ('.json', '.xml', '.csv'):
        print(path.name, hashlib.sha256(path.read_bytes()).hexdigest())
