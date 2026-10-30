"""Build independent expectations from retained public snapshots; stdlib only.

Run from the checkout root. Raw data and generated business tables stay ignored.
This extends workflow coverage, not the number of newly collected data sources.
"""
import csv
import hashlib
import json
import re
import runpy
import xml.etree.ElementTree as ET
from collections import Counter
from decimal import Decimal
from pathlib import Path

root = Path('outputs/business-validation-2026-10-30')
root.mkdir(parents=True, exist_ok=True)
snapshots = {
    'real-data-audit/cfqa.json': 'e4c08332a1f6aada430ac94fe62106fd557c3d80cd68c495118412bb7704bc7d',
    'broad-data-audit/tw-jobs.json': '9c359ee13ce64bdf328eb7e9b135ea68af8f61ff15c02a07d4ec69eda394a937',
    'broad-data-audit/tw-education.xml': '28fdad833de16689d8dd123f80cc7bc2ab2572c1c148efc65325eb318e0d7960',
    'broad-data-audit/tw-tourism.csv': '08d298d4d54992b1a3169b1dd528af89b1119fa82a0454a7d4350ac2aff87e18',
}
for name, expected in snapshots.items():
    actual = hashlib.sha256((Path('outputs') / name).read_bytes()).hexdigest()
    if actual != expected:
        raise ValueError(f'Snapshot mismatch: {name}; do not replace baseline hashes')

columns = ['case_id', 'domain', 'source', 'source_row', 'record_id', 'field',
           'raw_input', 'parse_input', 'parser', 'parser_unit', 'source_unit',
           'pay_period', 'transformation', 'expected_status', 'expected_value',
           'expected_upper', 'expected_qualifier', 'review_note']
rows = []


def add(domain, source, index, field, raw, parser='number', unit='', source_unit='',
        period='', transformation='none', status='parsed', expected='', upper='',
        qualifier='', text=None, note='', record_id=None):
    rows.append(dict(zip(columns, [f'{domain}:{len(rows)+1:06d}', domain, source,
        str(index), str(record_id) if record_id is not None else f'{index:06d}', field,
        raw, raw if text is None else text, parser, unit, source_unit, period,
        transformation, status, str(expected), str(upper), qualifier, note])))


numeric = re.compile(r'[+-]?(?:[0-9]+|[0-9]{1,3}(?:,[0-9]{3})+)(?:\.[0-9]+)?')


def scalar(raw, scale=1):
    if raw.strip() in ('', '-', 'NA'):
        return 'missing', ''
    if numeric.fullmatch(raw.strip()):
        return 'parsed', str(Decimal(raw.strip().replace(',', '')) * scale)
    return 'reject', ''


# Reuse the existing independently reviewed extraction/Decimal builder rather
# than introducing a second financial-span grammar or using cncleanr as oracle.
finance_data = runpy.run_path('docs/real-data-audit.py')
finance = finance_data['rows']
positions = {str(record['id']): index for index, record in enumerate(finance_data['records'], 1)}
assert len(positions) == len(finance_data['records'])
for index, item in enumerate(finance, 1):
    record_id, company, raw, expected, qualifier, status, unit, context = item
    add('finance', 'CFQA:test', positions[str(record_id)], 'answer_span', raw, parser='quantity',
        source_unit=unit, transformation='extracted_span_not_full_answer',
        status='parsed' if status == 'valid' else 'reject', expected=expected,
        qualifier=qualifier if status == 'valid' else '', record_id=record_id,
        note='Lexical span only; original answer ID retained; not a financial fact-check')

jobs = json.loads(Path('outputs/broad-data-audit/tw-jobs.json').read_text(encoding='utf-8-sig'))
for index, raw_record in enumerate(jobs, 1):
    record = {key.split('（')[0]: value for key, value in raw_record.items()}
    period = record['SALARYCD']
    for field in ('NT_L', 'NT_U'):
        status, expected = scalar(record[field])
        add('salary', 'TW:44062', index, field, record[field], unit='元',
            source_unit='TWD per source pay period', period=period,
            status=status, expected=expected)
    lo_status, lo = scalar(record['NT_L'])
    hi_status, hi = scalar(record['NT_U'])
    eligible = lo_status == hi_status == 'parsed' and 0 < Decimal(lo) <= Decimal(hi)
    # A source zero is not automatically an unknown upper bound or a zero salary.
    add('salary', 'TW:44062', index, 'salary_interval',
        record['NT_L'] + ' | ' + record['NT_U'], parser='range',
        source_unit='TWD per source pay period', period=period,
        transformation='derived_from_two_endpoint_fields',
        text=f'{lo}~{hi}' if eligible else '',
        status='parsed' if eligible else 'business_review',
        expected=lo if eligible else '', upper=hi if eligible else '',
        note='' if eligible else 'No defensible closed interval: missing/zero/reversed endpoint; retain source pay mode')
    if '依學經歷' in period:
        add('salary', 'TW:44062', index, 'SALARYCD', period, parser='range',
            period=period, status='reject', note='Pay-rule description is not a complete numeric interval')
    if index in (5, 39):
        add('salary', 'TW:44062', index, 'JOB_DETAIL', record['JOB_DETAIL'], parser='range',
            period=period, status='reject',
            note='Manually reviewed complete description: bonus/experience conditions; do not extract its first number')

education = ET.parse('outputs/broad-data-audit/tw-education.xml').getroot()
for index, record in enumerate(education, 1):
    for field in record:
        if not field.tag.endswith(('_千人', '_百分比')):
            continue
        raw = field.text or ''
        percentage = field.tag.endswith('_百分比')
        status, expected = scalar(raw, Decimal('.01') if percentage else 1)
        add('statistics', 'TW:34112:114', index, field.tag, raw,
            source_unit='proportion' if percentage else 'thousand persons',
            transformation='append_percent_to_percentage_points' if percentage else 'retain_source_thousands',
            text=raw.strip() + '%' if percentage and status == 'parsed' else raw,
            status=status, expected=expected)

# Supplemental monetary column-header workflow, not a corporate finance table.
with Path('outputs/broad-data-audit/tw-tourism.csv').open(encoding='utf-8-sig', newline='') as handle:
    for index, record in enumerate(csv.DictReader(handle), 1):
        for field, raw in record.items():
            if '萬元' not in field:
                continue
            status, expected = scalar(raw, Decimal(10000))
            add('money_header', 'TW:tourism', index, field.strip(), raw,
                unit='万元', source_unit='TWD', transformation='explicit_header_scale',
                status=status, expected=expected,
                note='Estimated tourism benefit; source text requiring interpretation is not a scalar')

with (root / 'cases.csv').open('w', encoding='utf-8', newline='') as handle:
    writer = csv.DictWriter(handle, fieldnames=columns)
    writer.writeheader()
    writer.writerows(rows)
manifest = {'validation_date': '2026-10-30', 'new_snapshot_downloads': 0,
            'basis': 'Retained hash-locked snapshots; attempted new official downloads timed out/reset',
            'input_sha256': snapshots,
            'cases_sha256': hashlib.sha256((root / 'cases.csv').read_bytes()).hexdigest(),
            'case_count': len(rows)}
(root / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print(Counter((row['domain'], row['expected_status']) for row in rows))
print('Cases:', len(rows), '; newly downloaded snapshots: 0')
