# CRAN submission comments

## Submission

Draft for a future `cncleanr` 0.2.13 submission; NOT submitted or ready to upload.
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
The diagnostic update adds explicit `cn_subset()` and original encoding-error
positions without changing result classes or ordinary diagnostic reasons.

## Test environments

- GitHub Actions: Ubuntu (R-devel, R-release, R-oldrel-1), Windows
  (R-release), and macOS (R-release)
- Ubuntu R-release additionally builds and checks the PDF reference manual.
- Record the final archive's checks in `docs/diagnostic-workflow.md`.
- Prior 0.2.5 win-builder and 0.2.9 native checks are historical only.
- Fresh win-builder / incoming checks remain required before a CRAN upload.

## R CMD check results

Use the exact 0.2.13 archive hash, commit and checks recorded in the diagnostic
workflow report. The 0.2.12 checks in `docs/systematic-hardening.md` are historical,
not validation of this update. Refresh this section immediately before upload.
GitHub 0.2.13 source commit: `80f24e761615a44efc7fe20a848f53682fad192e`.
Archive SHA-256: `5277308A76AF8E80AFDC6D4BAD1B5A26A1B009DF3E9F7750D987A846565E6752`.
Local `--as-cran --no-manual` (incoming disabled) and all five platform CI checks
passed, with 784 assertions each; Linux PDF/HTML manuals passed. ASAN, UBSAN
and Valgrind passed on the same package-source commit. See the diagnostic report
for actual run IDs and scope, not an assertion that CRAN pretests are complete.
Fresh win-builder and incoming checks are still outstanding for CRAN submission.
Rebuild/recheck and refresh this draft if the submitted archive changes.
Do not reuse a historical new-submission NOTE or another archive's clean result.

## Downstream dependencies

The CRAN package page showed no reverse-dependency section on 2026-10-09.
Recheck this immediately before submission; no downstream checks were run.
