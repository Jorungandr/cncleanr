"""Create auditable number spans and Decimal expectations from CFQA answers.

Run after downloading the pinned CFQA test split into outputs/real-data-audit.
This is a lexical parser audit, not a financial fact-check or NLP benchmark.
"""
import csv
import json
import re
from decimal import Decimal
from pathlib import Path

root = Path('outputs/real-data-audit')
records = json.loads((root / 'cfqa.json').read_text(encoding='utf-8'))
# Keep adjacent qualifiers and complete digit/comma runs; do not salvage a
# valid-looking substring from malformed grouping such as 368,75万元.
pattern = re.compile(
    r'(?P<prefix>不超过|不低于|不少于|至少|超过|大于|小于|约为|大约|约|近|超)?'
    r'\s*(?P<currency>人民币)?\s*'
    r'(?P<number>[+-]?\d[\d,]*(?:\.\d+)?)\s*'
    r'(?P<unit>万亿元|万亿|亿元|万元|千元|百万元|元|亿|万|[%％])'
    r'(?P<suffix>以上|以下|余|左右)?'
)
multipliers = {'万亿元': '1e12', '万亿': '1e12', '亿元': '1e8',
               '万元': '1e4', '千元': '1e3', '百万元': '1e6',
               '元': '1', '亿': '1e8', '万': '1e4', '%': '.01', '％': '.01'}
qualifiers = {'': 'exact', '约为': 'approx', '大约': 'approx', '约': 'approx',
              '近': 'approx', '超过': 'greater_than', '超': 'greater_than',
              '大于': 'greater_than', '小于': 'less_than',
              '不超过': 'at_most', '不低于': 'at_least', '不少于': 'at_least',
              '至少': 'at_least', '以上': 'at_least', '以下': 'at_most',
              '余': 'greater_than', '左右': 'approx'}
rows = []
for record in records:
    answer = record['答案']
    for match in pattern.finditer(answer):
        number = match['number']
        grouped = bool(re.fullmatch(r'[+-]?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d+)?', number))
        prefix, suffix = match['prefix'] or '', match['suffix'] or ''
        valid = grouped and not (prefix and suffix)
        expected = str(Decimal(number.replace(',', '')) * Decimal(multipliers[match['unit']])) if valid else ''
        rows.append([record['id'], record['公司'], match.group().strip(),
                     expected, qualifiers[prefix or suffix],
                     'valid' if valid else 'invalid', match['unit'],
                     answer[max(0, match.start()-25):match.end()+25]])
with (root / 'spans.tsv').open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t')
    writer.writerow(['id', 'company', 'input', 'expected', 'qualifier', 'status', 'unit', 'context'])
    writer.writerows(rows)
print(f'CFQA answers={len(records)}, numeric spans={len(rows)}')
