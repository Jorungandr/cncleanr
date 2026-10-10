# Rscript docs/formatted-performance.R [baseline library] [candidate library]
args <- commandArgs(trailingOnly = TRUE)
baseline <- if (length(args)) args[[1L]] else 'outputs/mixed-optimization/library'
candidate_library <- if (length(args) > 1L) args[[2L]] else 'outputs/formatted-optimization/library'
.libPaths(c(baseline, .libPaths()))
library(cncleanr)
candidate <- new.env(parent = asNamespace('cncleanr'))
paths <- list.files(file.path(candidate_library, 'cncleanr/libs'), recursive = TRUE, full.names = TRUE)
path <- paths[basename(paths) == paste0('cncleanr', .Platform$dynlib.ext)]
stopifnot(length(path) == 1L)
candidate$C_simple_numbers <- getNativeSymbolInfo('simple_numbers', dyn.load(path))
for (kind in c('number', 'quantity', 'range'))
  source(paste0('R/parse-cn-', kind, '.R'), local = candidate, encoding = 'UTF-8')
for (name in ls(candidate))
  if (is.function(candidate[[name]])) candidate[[name]] <- compiler::cmpfun(candidate[[name]])

grid <- expand.grid(
  prefix = c('', 'R', 'RM', 'RMB', 'rMb', 'CNY', '\u00a5', '\u4eba\u6c11\u5e01',
             '-RMB', 'RMB-', '-RMB+', '(', '(RMB', '(-', ' RMB '),
  body = c('3', '-3', '+3', '0', '.2', '1e308', '1e-324', '1 2', '1 234', '\uff13\uff0e\uff15', '', 'bad'),
  suffix = c('', '\u4e07', '\u5143', '\u4ebf\u5143', '%', '\u4e07%', ')', '\u5143)', '%)', '\u5143))'),
  stringsAsFactors = FALSE)
x <- c(do.call(paste0, grid), NA, '\u6682\u65e0', ' ( \uff13\uff0e\uff15\u4e07 ) ')
names(x) <- seq_along(x)
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  for (input in list(x, factor(x), character(), c(Inf, NaN, NA)))
    stopifnot(identical(suppressWarnings(old(input)), suppressWarnings(new(input))))
  stopifnot(identical(suppressWarnings(old(x, na = c('RMB3', '1 2'))),
    suppressWarnings(new(x, na = c('RMB3', '1 2')))))
  strict_message <- function(fun) tryCatch(fun(x, strict = TRUE), error = conditionMessage)
  stopifnot(identical(strict_message(old), strict_message(new)))
}
for (unit in c('\u5143', '\u5343\u5143', '\u4e07', '\u4ebf', '\u4e07\u4ebf'))
  stopifnot(identical(suppressWarnings(parse_cn_number(x, unit = unit)),
    suppressWarnings(candidate$parse_cn_number(x, unit = unit))))

id <- seq_len(100000L)
samples <- list(plain = paste0(id, '\u4e07'), currency = paste0('RMB', id, '\u4e07'),
  spaced_currency = paste0('RMB ', id, ' \u4e07'), accounting = paste0('(RMB', id, '\u5143)'),
  fullwidth = paste0(chartr('0123456789', '\uff10\uff11\uff12\uff13\uff14\uff15\uff16\uff17\uff18\uff19', as.character(id)), '\u4e07'),
  grouped = paste0(id, ' 123\u4e07'), invalid = rep('bad', length(id)))
for (name in names(samples)) {
  input <- samples[[name]]
  stopifnot(identical(suppressWarnings(parse_cn_number(input)),
    suppressWarnings(candidate$parse_cn_number(input))))
  timing <- function(fun) median(replicate(3,
    system.time(for (i in seq_len(5L)) suppressWarnings(fun(input)))[['elapsed']] / 5))
  cat(name, 'baseline/candidate seconds:', timing(parse_cn_number), timing(candidate$parse_cn_number), '\n')
}
cat('PASS: formatted grid, all parsers, header units, missing markers and strict messages\n')
