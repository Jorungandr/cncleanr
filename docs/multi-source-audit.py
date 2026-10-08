"""Generate independent Decimal expectations; raw data stays in outputs/.

Download the pinned files listed in multi-source-audit-report.md first.
Run: python docs/multi-source-audit.py
"""
import csv
import hashlib
import re
from decimal import Decimal
from pathlib import Path

root = Path('outputs/multi-source-audit')
rows = []
with (root / 'penguins_raw.csv').open(encoding='utf-8', newline='') as handle:
    birds = list(csv.DictReader(handle))
columns = ['Culmen Length (mm)', 'Culmen Depth (mm)', 'Flipper Length (mm)',
           'Body Mass (g)', 'Delta 15 N (o/oo)', 'Delta 13 C (o/oo)']
for index, bird in enumerate(birds, 1):
    for column in columns:
        value = bird[column]
        expected = '' if value == 'NA' else str(Decimal(value))
        rows.append(['penguins', index, column, value, expected, 'exact',
                     'missing' if value == 'NA' else 'valid', '', '', '', ''])

# Keep explicit ranges and +/- expressions whole, not a valid-looking endpoint.
number = r'[+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?'
pattern = re.compile(
    r'(?<![0-9.])(?P<prefix>不超过|不少于|不低于|至少|超过|大于|小于|约为|大约|约|近|超|>=|<=|>|<|≥|≤)?'
    r'\s*(?P<expr>' + number + r'(?:\s*[~～\-±]\s*' + number + r')?\s*[%％]'
    r'(?:\s*[~～\-±]\s*' + number + r'\s*[%％]?)?)'
    r'(?P<suffix>以上|以下|左右|余)?')
qualifiers = {'': 'exact', '约': 'approx', '约为': 'approx', '大约': 'approx',
              '近': 'approx', '超': 'greater_than', '超过': 'greater_than',
              '大于': 'greater_than', '>': 'greater_than', '≥': 'at_least',
              '>=': 'at_least', '不少于': 'at_least', '不低于': 'at_least',
              '至少': 'at_least', '不超过': 'at_most', '<=': 'at_most',
              '≤': 'at_most', '小于': 'less_than', '<': 'less_than',
              '以上': 'at_least', '以下': 'at_most', '左右': 'approx', '余': 'greater_than'}
with (root / 'csl.tsv').open(encoding='utf-8', newline='') as handle:
    abstracts = list(csv.reader(handle, delimiter='\t'))
for index, record in enumerate(abstracts, 1):
    text = record[1]
    # One-to-one character translation preserves offsets into the source text.
    normalized = text.translate(str.maketrans('０１２３４５６７８９．％＋－＜＞＝',
                                              '0123456789.%+-<>='))
    for match in pattern.finditer(normalized):
        prefix, suffix = match['prefix'] or '', match['suffix'] or ''
        expression = re.sub(r'\s+', '', match['expr']).replace('％', '%')
        simple = re.fullmatch(number + '%', expression)
        expected = str(Decimal(expression[:-1]) / 100) if simple else ''
        # A scalar adjacent to another numeric expression needs manual review.
        attached = bool(re.search(r'[0-9%±~～]\s*$', normalized[:match.start()]))
        status = 'valid' if simple and not (prefix and suffix) and not attached else 'review'
        interval = re.fullmatch('(' + number + r')%?[~～\-](' + number + ')%', expression)
        lower = upper = ''
        if interval and not (prefix or suffix or attached):
            lower, upper = [str(Decimal(x)/100) for x in interval.groups()]
            status = 'range' if Decimal(lower) <= Decimal(upper) else 'review'
        rows.append(['CSL', index, 'abstract', text[match.start():match.end()].strip(), expected,
                     qualifiers[prefix or suffix], status, expression,
                     text[max(0, match.start()-20):match.end()+20], lower, upper])
with (root / 'cases.tsv').open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t')
    writer.writerow(['source', 'row', 'field', 'input', 'expected', 'qualifier',
                     'status', 'expression', 'context', 'lower', 'upper'])
    writer.writerows(rows)
print('Penguin rows:', len(birds), '; CSL abstracts:', len(abstracts))
for name in ['penguins_raw.csv', 'csl.tsv', 'cases.tsv']:
    print(name, hashlib.sha256((root / name).read_bytes()).hexdigest())
