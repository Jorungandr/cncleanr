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

GitHub 0.2.12 archive SHA-256:
`9C9B6C06D7D2FB893C6F17AFE1C2C6D4BA55CE90D91B75144039F7353DF324E7`.
Fixed tag commit: `fd52a635a759c076d21f9241fd8c4b16db696f3d`.
Local Windows R 4.6.1 `--as-cran --no-manual`, incoming disabled: Status OK,
633 passing assertions. Final-tag five-platform CI: Status OK throughout;
Linux PDF and HTML manuals passed. clang-ASAN, clang-UBSAN and Valgrind checks
passed on the identical package-source checkpoint; see linked release evidence.
Fresh win-builder and incoming checks are still outstanding for CRAN submission.
Rebuild/recheck and refresh this draft if the submitted archive changes.
Do not reuse a historical new-submission NOTE or another archive's clean result.

## Downstream dependencies

The CRAN package page showed no reverse-dependency section on 2026-10-09.
Recheck this immediately before submission; no downstream checks were run.
