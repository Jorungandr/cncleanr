# CRAN submission comments

## Submission

This will be the first CRAN submission of `cncleanr`.

## Test environments

- Local: Windows 11 x64 (build 26200), R 4.6.1 (ucrt)
- The `0.2.4` release candidate passed the following GitHub Actions matrix:
  - Ubuntu, R-devel
  - Ubuntu, R-release
  - Ubuntu, R-oldrel-1
  - Windows, R-release
  - macOS, R-release

## R CMD check results

The `0.2.4` release candidate was built from source and checked locally on the
environment above.

All five jobs in the GitHub Actions matrix completed
`R CMD check --as-cran --no-manual` successfully for this release candidate.

The local `R CMD check --as-cran --no-manual` result was 1 ERROR, 0 WARNINGs,
and 1 NOTE.

The check ran `tests/parser.R` and `tests/testthat.R`. The dependency-free
test completed successfully, and testthat reported 108 passes, 0 failures,
0 warnings, and 0 skips. The ERROR is a local R/toolchain exit failure after
the successful testthat summary (Windows status `-1073741819`), rather than a
test failure. The same exit failure occurs after successful standalone runs
of testthat and other tools that load the local `cli`/`rlang` installation.
The standard test runner has not been changed to conceal this failure.

The CRAN incoming-feasibility NOTE reports "New submission", as expected for
the package's first CRAN submission. It also reports connection timeouts while
checking three GitHub URLs. All three URLs are valid; the local R process could
not connect to GitHub during the remote check.

Auxiliary checks found no invalid URLs and no spelling errors. `lintr` reported
29 line-length findings and no other lint types; these are existing regular
expressions, Unicode literals, documentation examples, and test vectors.
File-level coverage of the same testthat files was 92.370572%. The normal
`covr::package_coverage()` route was also affected by the local post-test exit
failure, so the measured result used `covr::file_coverage()` without changing
the package test runner.

## Downstream dependencies

There are currently no known downstream dependencies (0).
