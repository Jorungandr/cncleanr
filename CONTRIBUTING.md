# Contributing to cncleanr

Thank you for helping improve `cncleanr`. Contributions are most useful when
they are small, reproducible, and based on formats found in real Chinese data.

## Development setup

You need a current R installation, Git, and the package development tools
declared in `DESCRIPTION`. Building from source may also require Rtools on
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
