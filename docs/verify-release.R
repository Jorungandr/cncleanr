# Rscript --vanilla docs/verify-release.R <source.tar.gz> <installed-library> [vVERSION]
# Run from the matching repository checkout, including after asset download.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 2:3)
archive <- normalizePath(args[[1L]], mustWork = TRUE)
lib <- normalizePath(args[[2L]], mustWork = TRUE)
expected <- read.dcf('DESCRIPTION')[1L, 'Version']
stopifnot(basename(archive) == paste0('cncleanr_', expected, '.tar.gz'))
if (length(args) == 3L) stopifnot(args[[3L]] == paste0('v', expected))
members <- utils::untar(archive, list = TRUE)
stopifnot(all(grepl('^cncleanr(/|$)', members)),
          !any(grepl('(^|/)\\.\\.(/|$)|\\\\', members)),
          !any(grepl('(^|/)(outputs|docs|[.]vscode|[.]git)(/|$)|[.](o|dll|so)$', members)))
verify <- function() {
  directory <- tempfile('cncleanr-release-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  utils::untar(archive, exdir = directory)
  root <- file.path(directory, 'cncleanr')
  source_description <- read.dcf('DESCRIPTION')
  built_description <- read.dcf(file.path(root, 'DESCRIPTION'))
  canonical <- function(x) gsub('[[:space:]]+', ' ', x)
  # R CMD build folds fields such as Suggests into one line.
  stopifnot(identical(canonical(source_description),
    canonical(built_description[, colnames(source_description), drop = FALSE])))
  required <- c('NAMESPACE', 'LICENSE', 'README.md', 'NEWS.md',
    list.files(c('R', 'src', 'man', 'tests', 'inst'), recursive = TRUE, full.names = TRUE))
  required <- required[!grepl('[.](o|dll|so)$|/symbols[.]rds$', required)]
  stopifnot(all(file.exists(file.path(root, required))))
  # Git may check text out as CRLF while the source archive contains LF.
  different <- unname(tools::md5sum(required)) != unname(tools::md5sum(file.path(root, required)))
  for (file in required[different])
    stopifnot(identical(readLines(file, warn = FALSE, encoding = 'UTF-8'),
      readLines(file.path(root, file), warn = FALSE, encoding = 'UTF-8')))
}
verify()
library(cncleanr, lib.loc = lib)
stopifnot(as.character(packageVersion('cncleanr', lib.loc = lib)) == expected,
          identical(parse_cn_number(c('3万', '１２．５％')), c(30000, .125)),
          identical(parse_cn_number('1e-330万亿'), 1e-318),
          parse_cn_quantity('约3万')$qualifier == 'approx',
          parse_cn_range('3-5万')$upper == 50000,
          nrow(cn_problems(suppressWarnings(parse_cn_range('3%-5元')))) == 1L)
cat('PASS: checkout/archive/installed version and parser smoke checks:', expected, '\n')
