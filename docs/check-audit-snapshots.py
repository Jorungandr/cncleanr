"""Verify historical input snapshots before generating gold values (stdlib).

Run from the repository root: python docs/check-audit-snapshots.py [all|finance|multi|broad]
Dynamic sources may change; a mismatch is not a parser failure. Do not overwrite
the recorded baseline hash to make this check pass.
"""
import hashlib
import sys
from pathlib import Path

groups = {
    "finance": {
        "real-data-audit/cfqa.json": "e4c08332a1f6aada430ac94fe62106fd557c3d80cd68c495118412bb7704bc7d",
        "real-data-audit/jobs.csv": "60e97755c4faf8cd2a2290364527654e7b421db31ae3da783614de1dbe90accb",
    },
    "multi": {
        "multi-source-audit/csl.tsv": "51900a71a26193525e98fa4e65c0e78ea4ca0b84cd1f0da0de0690ffdb85791d",
        "multi-source-audit/penguins_raw.csv": "144f623143c9360fd77322a4f86acb06dc198814dbd2669724c63e6457b907bd",
    },
    "broad": {
        "broad-data-audit/worldbank.json": "9b8cfeb9a6eed0499506a4ba0b1a297dcf77eff00570562a9c30ab61b7071e3c",
        "broad-data-audit/tw-education.xml": "28fdad833de16689d8dd123f80cc7bc2ab2572c1c148efc65325eb318e0d7960",
        "broad-data-audit/tw-jobs.json": "9c359ee13ce64bdf328eb7e9b135ea68af8f61ff15c02a07d4ec69eda394a937",
        "broad-data-audit/tw-air.json": "cd23ba030e1f076a40be3bbae8ad4b1b7ab8a383798ab10c05d51be9a47b09db",
        "broad-data-audit/tw-tourism.csv": "08d298d4d54992b1a3169b1dd528af89b1119fa82a0454a7d4350ac2aff87e18",
    },
}
selection = sys.argv[1] if len(sys.argv) == 2 else "all"
if len(sys.argv) > 2 or selection not in ("all", *groups):
    sys.exit("Usage: python docs/check-audit-snapshots.py [all|finance|multi|broad]")
failed = False
for group, files in groups.items():
    if selection not in ("all", group):
        continue
    for name, expected in files.items():
        path = Path("outputs") / name
        actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else "MISSING"
        ok = actual == expected
        print("OK" if ok else "FAIL", path, actual)
        failed |= not ok
sys.exit(1 if failed else 0)
