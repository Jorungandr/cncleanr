# Rscript docs/numeric-conversion-performance.R <new-library> <0.2.14-library>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
library(cncleanr, lib.loc = normalizePath(args[[1]], mustWork = TRUE))
stopifnot(read.dcf(file.path(args[[2]], 'cncleanr', 'DESCRIPTION'))[1, 'Version'] == '0.2.14')
baseline <- new.env(parent = asNamespace('cncleanr'))
invisible(lazyLoad(file.path(args[[2]], 'cncleanr', 'R', 'cncleanr'), envir = baseline))
old <- baseline$parse_cn_number
environment(old) <- asNamespace('cncleanr')
new <- parse_cn_number
datasets <- list(integer = seq_len(100000L),
                 double = seq_len(100000L) / 7,
                 character = as.character(seq_len(100000L)))
cat(R.version.string, '\nLoaded:', find.package('cncleanr'), '\n')
for (name in names(datasets)) {
  x <- datasets[[name]]
  stopifnot(identical(old(x, unit = '\u4e07'), new(x, unit = '\u4e07')))
  measure <- function(fun) system.time(for (j in 1:3) fun(x, unit = '\u4e07'))[['elapsed']] / 3
  times <- matrix(0, 7, 2)
  for (i in 1:7) {
    gc()
    if (i %% 2) times[i, ] <- c(measure(old), measure(new))
    else times[i, 2:1] <- c(measure(new), measure(old))
  }
  cat(name, '100000 rows, old/new median seconds:', apply(times, 2, median), '\n')
}
cat('PASS: complete ordinary-input results identical; same native routines.\n')
