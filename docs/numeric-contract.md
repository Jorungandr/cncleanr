# 数值转换结果校验 / Numeric conversion contract

## Root cause and fix

Installed 0.2.17 reproduced malformed S3 `as.double()` behavior: a three-cell
unnamed input could become one cell, and a method returning text could produce
text-valued parser results. Named inputs could instead fail later while assigning
names, so this was not a consistent argument-validation error.

0.2.18 routes all three parser numeric branches and numeric SPSS preparation
through `cn_numeric_values()`. It calls `as.double()` once, then requires double
storage, no class/object, no dimensions and the original length. It does not
attempt to invent lost rows or coerce an invalid method's result a second time.
Legitimate conversion warnings propagate. Plain numeric vectors do not acquire
an extra element-wise scan; character parsing and C sources are unchanged.

本次只防止返回类型、维度或长度异常；不能判断任意自定义方法是否篡改了数值含义，
也不解决 double 精度限制。异常方法现在报错，是有意的安全兼容性变化。

## Checks

- New dependency-free regression: 173 assertions; wrong length (short, long,
  empty), storage type, retained class, matrix, named input, SPSS metadata,
  ordinary/header entries, empty valid input, nonfinite values and warnings.
  The new test first failed against installed 0.2.17, then passed after repair.
- Local clean committed source archive check: `Status: OK`; 1,181 assertions,
  zero failures, warnings or skips. Windows 11, R 4.6.1, UCRT GCC 15.2.
  Local check used `--no-manual`, disabled incoming checks and remote
  dependency-cycle lookup; PDF and online checks are not claimed locally.
- Actual haven 2.5.5 / units 1.0.1 / bit64 4.8.6: all 77 checks passed.
  System audit: 2,454 generated consistency checks and 28 optional bit64 checks
  passed. Consistency comparisons are not independent semantic proof.
- Existing financial, research, penguin and multi-domain data audits passed;
  all nine retained source snapshot hashes matched. No newly collected data
  or broader unsupported syntax is claimed.
- C unchanged; no new sanitizer or Valgrind run is claimed. No new dependencies.

## Timing regression

Five alternating paired medians on the same machine, warmed and checked for
identical results; old 0.2.17 R code uses the same unchanged C implementation:

| Interface / rows | 0.2.17 seconds | 0.2.18 seconds |
| --- | ---: | ---: |
| number text / 100,000 | 0.010 | 0.010 |
| number numeric / 100,000 | 0.0002 | 0.0001 |
| quantity text / 100,000 | 0.110 | 0.110 |
| range text / 20,000 | 0.310 | 0.280 |

Very short timings, especially numeric input, are timer-limited. These are
regression samples, not a stable speedup claim or a guarantee of zero overhead.
The task-local reproduction is `outputs/numeric-contract/performance.R`.

## Reproduction

```text
Rscript docs/import-types-audit.R <installed-library> <optional-test-library>
Rscript docs/system-audit.R <installed-library> <optional-test-library>
Rscript docs/verify-release.R <cncleanr_0.2.18.tar.gz> <installed-library> v0.2.18
```

## GitHub publication

Published [v0.2.18](https://github.com/Jorungandr/cncleanr/releases/tag/v0.2.18)
from `83fb6069d2c5b0cba078eb44d6340d3f4125485d`, fixed annotated tag object
`71f10487fa445790efb5749888ab4294aad5106a`.
[CI run 39049618104](https://github.com/Jorungandr/cncleanr/actions/runs/39049618104)
passed on Ubuntu devel/release/oldrel-1, Windows release and macOS release.
Each job's log reports `Status: OK` and 1,181 passing assertions with no failures,
warnings or skips. Ubuntu release additionally passed PDF and HTML manual checks.

The public source asset is 54,311 bytes, SHA256
`bb5777a2651cf74ee385ad158495d510e295fb701fcfff1486ada0401468172c`.
Unauthenticated download matched this hash. The downloaded archive was installed
into a separate library; source/archive/installed verification passed.
The complete testthat suite and `tests/parser.R` passed again against that public
installation, as did all 77 real imported-type, 2,454 generated consistency and
28 optional bit64 audit checks.
No CRAN submission.
