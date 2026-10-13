# CRAN submission comments

## Submission

Draft for a future `cncleanr` 0.2.12 submission; NOT submitted or ready to upload.
Recheck the current CRAN version and policies immediately before submission.

The update adds explicit monetary table-header units to `parse_cn_number()`,
thousand-yuan amounts, the shorthand greater-than qualifier, and support for
one approximation prefix combined with an approximation suffix.
The optional `unit` argument is appended, preserving existing positional calls.
The package now uses registered C numeric and normalization routines; source
installation requires a C compiler (`NeedsCompilation: yes`). No runtime R
dependencies were added. Subsequent changes reject malformed UTF-8, validate
range grouping/missing markers, incompatible range dimensions and final
underflow, and preserve names. Bilingual examples and regressions were expanded.

## Test environments

- GitHub Actions: Ubuntu (R-devel, R-release, R-oldrel-1), Windows
  (R-release), and macOS (R-release)
- Ubuntu R-release additionally builds and checks the PDF reference manual.
- Record the final archive's checks in `docs/systematic-hardening.md`.
- Prior 0.2.5 win-builder and 0.2.9 native checks are historical only.
- Fresh win-builder / incoming checks remain required before a CRAN upload.

## R CMD check results

Replace this section with the exact final archive hash, commit, environments,
check statuses and explanations before submission. Do not reuse the historical
new-submission NOTE, old test counts or a previous archive's clean result.
Local checks without manuals/incoming are not full CRAN pre-submission checks.

## Downstream dependencies

The CRAN package page showed no reverse-dependency section on 2026-10-09.
Recheck this immediately before submission; no downstream checks were run.
