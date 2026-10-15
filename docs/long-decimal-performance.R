# Rscript docs/long-decimal-performance.R <new-library> <0.2.13-library>
# Compare pre/post parser functions and their native paths in one process.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
library(cncleanr, lib.loc = normalizePath(args[[1]], mustWork = TRUE))
baseline_path <- normalizePath(file.path(args[[2]], 'cncleanr', 'R', 'cncleanr'), mustWork = FALSE)
baseline <- new.env(parent = asNamespace('cncleanr'))
invisible(lazyLoad(baseline_path, envir = baseline))
stopifnot(exists('convert_cn_scaled_boundary', baseline, inherits = FALSE))
old <- new.env(parent = asNamespace('cncleanr'))
namespace <- asNamespace('cncleanr')
for (name in ls(namespace, all.names = TRUE)) {
  fun <- get(name, namespace)
  if (is.function(fun) && identical(environment(fun), namespace)) {
    environment(fun) <- old
    old[[name]] <- fun
  }
}
old$convert_cn_scaled_boundary <- baseline$convert_cn_scaled_boundary
# Restore the old number parser and native routines as well: the new fast path
# explicitly defers >1,100-byte numeric bodies, even if a platform accepts them.
old$parse_cn_number <- baseline$parse_cn_number
environment(old$parse_cn_number) <- old
dll <- list.files(file.path(args[[2]], 'cncleanr', 'libs'), recursive = TRUE, full.names = TRUE)
dll <- dll[basename(dll) == paste0('cncleanr', .Platform$dynlib.ext)]
stopifnot(length(dll) == 1L)
old_dll <- dyn.load(normalizePath(dll, mustWork = TRUE))
old$C_simple_numbers <- getNativeSymbolInfo('simple_numbers', old_dll)
old$C_normalize_characters <- getNativeSymbolInfo('normalize_characters', old_dll)
cases <- list(
  number_distinct = list('number', paste0(seq_len(1000000L), '\u4e07'), 3L),
  number_formatted = list('number', rep(c('\uff11\uff12\uff0e\uff15%', '1,234.5\u4e07', 'bad', 'NA'), 25000L), 2L),
  number_extreme = list('number', rep(c('1e309%', '1e-330\u4e07\u4ebf', '1e-999'), 1000L), 2L),
  quantity_distinct = list('quantity', paste0('\u7ea6', seq_len(100000L), '\u4e07'), 1L),
  range_distinct = list('range', paste0(seq_len(100000L), '-', seq_len(100000L)+1L, '\u4e07'), 1L)
)
cat('R:', R.version.string, '\nNew library:', find.package('cncleanr'), '\n')
for (name in names(cases)) {
  case <- cases[[name]]
  previous <- old[[paste0('parse_cn_', case[[1]])]]
  current <- get(paste0('parse_cn_', case[[1]]), namespace)
  x <- case[[2]]
  repeats <- case[[3]]
  stopifnot(identical(suppressWarnings(previous(x)), suppressWarnings(current(x))))
  measure <- function(fun) system.time(for (i in seq_len(repeats))
    suppressWarnings(fun(x)))[['elapsed']] / repeats
  # Alternate order and collect beforehand to reduce GC/order effects.
  timings <- matrix(NA_real_, 5, 2)
  for (i in seq_len(5L)) {
    gc()
    if (i %% 2L) timings[i, ] <- c(measure(previous), measure(current))
    else timings[i, 2:1] <- c(measure(current), measure(previous))
  }
  cat(name, 'rows', length(x), 'old/new median seconds:', apply(timings, 2, median), '\n')
}
x <- paste0(strrep('1', 5000), 'e-4999')
stopifnot(is.na(suppressWarnings(old$parse_cn_number(x))),
          identical(parse_cn_number(x, strict = TRUE), 10/9))
cat('long_decimal_100 distinct input median seconds:',
    median(replicate(5L, system.time(parse_cn_number(
      paste0(strrep('1', 4995), sprintf('%05d', seq_len(100L)), 'e-4999'),
      strict = TRUE))[['elapsed']])), '\n')
cat('PASS: unchanged complete outcomes on normal datasets; long decimal rescued.\n')
