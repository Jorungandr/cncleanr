# CRAN submission comments

## Submission

Draft for updating `cncleanr` from CRAN 0.2.5 to 0.2.7; not yet submitted.

The update adds explicit monetary table-header units to `parse_cn_number()`,
thousand-yuan amounts, the shorthand greater-than qualifier, and support for
one approximation prefix combined with an approximation suffix.
The optional `unit` argument is appended, preserving existing positional calls.
Tests and bilingual cleaning examples have been expanded; no dependencies added.

## Test environments

- GitHub Actions: Ubuntu (R-devel, R-release, R-oldrel-1), Windows
  (R-release), and macOS (R-release)
- Ubuntu R-release additionally builds and checks the PDF reference manual.
- All five jobs passed for commit 49fff9bbc87aa79c8030acbbd1c7c78e00921857:
  https://github.com/Jorungandr/cncleanr/actions/runs/37796592146
- R-hub and win-builder results from 0.2.5 are historical, not checks of 0.2.7.
  Fresh pre-submission checks remain to be completed before uploading.

## R CMD check results

The five GitHub Actions jobs completed successfully; the R-devel log reports
`Status: OK`. Do not reuse the historical new-submission NOTE for this update.
Recheck the final source tarball and record its results before uploading.
Local Windows R 4.6.1 check on 2026-10-09 used `--as-cran --no-manual`
with remote incoming checks disabled. It reported 1 ERROR because the
testthat subprocess exited unsuccessfully after reporting
`FAIL 0 | WARN 0 | SKIP 0 | PASS 209`. This is not a clean local check;
investigate or obtain fresh independent validation before submission.

## Downstream dependencies

The CRAN package page showed no reverse-dependency section on 2026-10-09.
Recheck this immediately before submission; no downstream checks were run.
