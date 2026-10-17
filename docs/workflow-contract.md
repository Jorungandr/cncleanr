# 工作流与文档一致性验收 / Workflow and documentation validation

## Findings and changes — 2026-10-18

This round found documentation/coverage gaps, not a reproduced parser algorithm
defect. Existing chunk/source-row handling and parser semantics remained intact.
No changes to `R/`, `src/`, DESCRIPTION, dependencies or public arguments.

- Expanded the existing workflow test by 120 assertions: shared exact-input gold
  values across all three parsers; empty/irregular chunks; selected, reordered
  and repeated source rows; local-to-source diagnostic mapping; quantities and
  ranges; RDS round-trips including diagnostics, NaN and negative zero.
- New `docs/readme-audit.R` reads literal fenced R blocks from both READMEs and
  checks their code agrees. It executes them in an automatically removed temporary
  directory, avoiding writes to the checkout. The intended strict-mode failure is
  asserted, not mistaken for a passing example. Unexpected warnings/errors fail.
- Each language has three installation blocks intentionally not executed. With
  actual units 1.0.1 installed, all ten remaining blocks ran (including one
  expected error). Without units, nine ran and the one unexecuted optional block
  was explicitly reported. Installation commands are not validated by this audit;
  printed `#>` formatting is not byte-compared across platforms.
- Updated both CSV/workflow guides and README editions: ordinary CSV can round
  binary64 tail digits, lose negative-zero sign, collapse NA/NaN with `na=''`,
  and does not store R problem attributes. Direct local reproduction with
  `1+2^-52` exported `1`. This is base CSV serialization, not parser truncation.
  Use source text/IDs/status/review tables for interchange and trusted RDS files
  for exact R-object preservation. Preserve interval inclusivity flags separately.

## Checks

Source checkpoint: `274e48369b9550407e1a98016e38795da6feb5fc`.
Local clean committed archive R CMD check: `Status: OK`, 1,301 assertions,
zero failures/warnings/skips. R 4.6.1, Windows 11, UCRT GCC 15.2.
Local check used `--as-cran --no-manual`, disabled incoming checks and remote
dependency-cycle lookup; no local PDF/online-check certification is claimed.
Checkout/archive/installed-source verification passed against the checked archive.

Real haven 2.5.5 / units 1.0.1 / bit64 4.8.6 audit: 77 checks passed.
System audit: 2,454 generated consistency and 28 optional bit64 checks passed.
Generated agreement is not independent semantic proof. All nine retained public
data snapshot hashes matched. No new data collection, speed benchmark, sanitizer
or Valgrind run is claimed; parser R/C code is unchanged.

Run from the checkout root with the intended package installed:

```text
Rscript docs/readme-audit.R <installed-library> [optional-units-library]
Rscript docs/import-types-audit.R <installed-library> <optional-test-library>
Rscript docs/system-audit.R <installed-library> <optional-test-library>
```

This updates main's documentation, tests and CI, not the existing v0.2.18 release.
The published archive still has 1,181 assertions; the expanded 1,301-assertion
suite belongs to the new checkout. Existing tag, release and 54,311-byte asset
remain unchanged (SHA256
`bb5777a2651cf74ee385ad158495d510e295fb701fcfff1486ada0401468172c`).
No new version or CRAN submission is needed for this documentation/test-only work.

## Cross-platform completion

[CI run 39051208534](https://github.com/Jorungandr/cncleanr/actions/runs/39051208534)
passed all five jobs: Ubuntu devel/release/oldrel-1, Windows release and macOS
release. Each reports `Status: OK` and 1,301 passing assertions, no failures,
warnings or skips in the package suite. Ubuntu release passed PDF/HTML manuals.
The separate README audit ran nine blocks per language on each platform,
including the asserted strict error, excluded three installation blocks and
explicitly reported the one optional units block not run. The local real-units
execution above supplies separate optional-example evidence, not five-platform
units certification.
