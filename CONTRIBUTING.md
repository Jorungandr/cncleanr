# Contributing to cncleanr

Thank you for helping improve `cncleanr`. Contributions are most useful when
they are small, reproducible, and based on formats found in real Chinese data.

## Development setup

You need a current R installation, Git, and the package development tools
declared in `DESCRIPTION`. Building from source requires a C compiler: Rtools on
Windows, the Xcode command-line tools on macOS, or the usual compiler toolchain
on Linux. Clone the repository and install the development dependencies:

```sh
git clone https://github.com/Jorungandr/cncleanr.git
cd cncleanr
```

```r
install.packages("pak")
pak::pak(".", dependencies = TRUE)
install.packages(c("devtools", "roxygen2"))
```

When `pak` is unavailable, install the packages listed under `Suggests` in
`DESCRIPTION` manually.

## Testing changes

Run the complete development suite from the repository root:

```r
devtools::test()
```

Before opening a pull request, build and check the package as R will check the
source archive:

```sh
R CMD build .
R CMD check cncleanr_VERSION.tar.gz
```

Replace `VERSION` with the version in the archive produced by `R CMD build`.
On Windows, run these commands from a shell where `R` is on `PATH`, or replace
`R` with the full path to `R.exe`.

## Documentation

Public functions are documented with roxygen comments in `R/`. Edit those
comments rather than editing generated files in `man/` directly, then
regenerate the Rd files with:

```r
roxygen2::roxygenise(".", roclets = "rd")
```

Keep the Chinese and English README descriptions consistent when a public
behavior or example changes.

## Parser cases and fixtures

Every parser change should include focused tests. Prefer adding representative
UTF-8 cases to `tests/testthat/fixtures/` when they model values copied from
tables, spreadsheets, PDFs, web pages, or statistical reports. Add a normal
unit test when a fixture would make the intent less clear.

Preserve the public problem-reporting contract. In particular, existing
`cn_problems()` reason strings and their input indices are stable user-facing
output. Do not rename, combine, or reorder problem reasons without discussing
the compatibility impact first. A new accepted format should also have tests
for nearby malformed input so that the parser does not become overly
permissive.

## Pull requests

Keep pull requests narrowly scoped. Explain the real source format, the
intended semantics, and any compatibility trade-offs. Include tests and update
documentation when behavior changes. Avoid unrelated formatting, generated
files, or dependency changes in the same pull request.

Package versions, release tags, GitHub releases, and CRAN submissions are
maintainer responsibilities. Contributors should not update `Version` in
`DESCRIPTION`, create release commits, or move tags unless a maintainer asks
them to do so.

For maintainer-requested cncleanr updates, complete the GitHub workflow in one
pass: implementation, bilingual documentation, version/release notes, checks,
fixed tag, checked source attachment, release publication and post-release
verification. Do not require separate confirmations for each ordinary step.
Pause only for blockers, ambiguity or materially new authority. Requests limited
to explanation/review do not authorize publication; CRAN submission always
requires separate authorization. Never move an existing published version tag.

For native-code changes, run the fixed-seed differential and encoding regressions
in `tests/testthat/test-native-stability.R` as part of the full test suite. Use
the existing R-hub workflow with `config=clang-asan,clang-ubsan,valgrind` and
inspect the actual check logs before publishing; normal platform checks alone
are not memory-safety evidence. See `docs/native-stability.md` for this audit.

Pair differential tests with independent literal expected values; agreement
between native and R paths cannot detect a shared semantic bug. See
`test-systematic-hardening.R` for units, extreme scaling and metadata cases.
The corrected grouped-endpoint diagnostics in 0.2.12 are an intentional bug fix;
existing reason spellings are retained, with new reasons for incompatible units,
final nonzero underflow and excessive separators.

Current data audits require an installed package matching this checkout's
DESCRIPTION; see [snapshot reproduction](docs/data-audit-reproduction.md).
Historical benchmark scripts are not current acceptance gates.

Before publishing, run `docs/verify-release.R` on the exact checked archive and
again on the downloaded public attachment. Record SHA-256, commit, CI and native
tool run IDs in the release report; never treat old results as a fresh check.
CRAN drafts must be refreshed against that archive and need separate approval.

CI currently validates R release/devel/oldrel-1 on Linux and R release on Windows
and macOS. Older R versions and every locale/architecture are not certified;
valid UTF-8/Latin-1 regressions are not universal encoding support. No arbitrary
minimum R version is claimed without testing it.
