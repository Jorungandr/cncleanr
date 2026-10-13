# 数据审计复现 / Data audit reproduction

以下是当前入口；旧报告保留原测试时点，不代表最新验证结果。
Run from the repository root. Historical reports retain their original versions;
their results are not evidence for a new release.

## 安装当前包 / Install this checkout

```sh
mkdir -p outputs/audit-library
R CMD INSTALL --library=outputs/audit-library .
```

PowerShell uses `New-Item -ItemType Directory -Force outputs/audit-library`.
Source installation needs a C compiler. On Windows use matching Rtools and,
if necessary, `docs/run-r.ps1 -Executable <R.exe> -RArguments ...`.
All three current scripts print the loaded version/path and refuse a version
different from this checkout's DESCRIPTION. They no longer source uncompiled R
functions or default to old `outputs/release-*` libraries. `jsonlite` is needed
only by the financial audit, not by the package.

## 获取与验证快照 / Acquire and verify snapshots

Create `outputs/real-data-audit`, `outputs/multi-source-audit` and
`outputs/broad-data-audit`. Use these exact filenames and source versions:

| File | Source |
| --- | --- |
| `real-data-audit/cfqa.json` | [CFQA fixed test split](https://raw.githubusercontent.com/ygan/CFQA/61c9ec3c4335d0411a1735cd228af8b3ead114fc/dataset/split_by_company/split_by_company_test.json) |
| `real-data-audit/jobs.csv` | [Recruitment snapshot](https://raw.githubusercontent.com/kknee-dev/recruit-hub/3d0b2aba47f827b7f6e9ae42049113b5f45cbc49/data/jobs-2026-09-03.csv) |
| `multi-source-audit/csl.tsv` | [CSL fixed test set](https://raw.githubusercontent.com/ydli-ai/CSL/0f1ac0626d584cd3c72f8be26d329eb4f967cfd0/benchmark/ts/test.tsv) |
| `multi-source-audit/penguins_raw.csv` | [Penguin measurements](https://raw.githubusercontent.com/allisonhorst/palmerpenguins/8957207b78d6ccd1b4654a9dd9c9041b657478ab/inst/extdata/penguins_raw.csv) |
| `broad-data-audit/worldbank.json` | WDI query in [the broad audit report](broad-data-audit-report.md) |
| `broad-data-audit/tw-education.xml`, `tw-jobs.json`, `tw-air.json`, `tw-tourism.csv` | Official dataset resource links in the same report |

For example, use `curl -L --fail <URL> -o <outputs/path>` or PowerShell
`Invoke-WebRequest -Uri <URL> -OutFile <outputs/path>`. Download deliberately;
these scripts do not silently fetch or redistribute data.

```sh
python docs/check-audit-snapshots.py all
```

Use `finance`, `multi` or `broad` instead of `all` to check a subset. Missing
files or a SHA-256 mismatch exit nonzero. Dynamic government APIs may no longer
serve the historical bytes: report a new snapshot separately with its date,
hash and gold-value review, rather than replacing baseline hashes or claiming
an exact reproduction. Source availability and licensing remain source-specific.
Recruitment contents have third-party rights and no salary values; this file
is only an inventory check, not additional successful salary cases.

## 生成答案并运行 / Generate gold values and run

```sh
python docs/real-data-audit.py
python docs/multi-source-audit.py
python docs/broad-data-audit.py
Rscript --vanilla docs/real-data-audit.R outputs/audit-library
Rscript --vanilla docs/multi-source-audit.R outputs/audit-library
Rscript --vanilla docs/broad-data-audit.R outputs/audit-library
```

Python builders use stdlib Decimal, not the parser being tested, for gold
values. Results are named `results-VERSION.tsv`. Raw/derived fields and review
cases must remain distinguished. These lexical samples do not certify financial
facts, arbitrary prose or all domains. Small independent regressions in
`tests/testthat/test-systematic-hardening.R` run without these downloads.

## 历史性能脚本 / Historical benchmarks

Performance work is closed. Old benchmark source, baseline libraries and DLLs
must match their historical commit; they are not current acceptance scripts.
`number-performance.R` originated at `60052ba`, `native-performance.R` at
`a5be456`. Review `git show <commit>:docs/<script>` and use a separate matching
checkout/library to reproduce that point in time; local outputs are not shipped.
Current copies fail early with guidance instead of sourcing current R code into
an incompatible historical namespace. Timings are not promises for later versions.
