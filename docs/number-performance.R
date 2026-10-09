# Rscript docs/number-performance.R [unchanged baseline library]
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(if (length(args)) args[[1L]] else
  'outputs/quantity-optimization/library', .libPaths()))
library(cncleanr)
candidate <- new.env(parent = asNamespace('cncleanr'))
for (file in c('number', 'quantity', 'range'))
  source(paste0('R/parse-cn-', file, '.R'), local = candidate, encoding = 'UTF-8')
for (name in ls(candidate))
  if (is.function(candidate[[name]])) candidate[[name]] <- compiler::cmpfun(candidate[[name]])
grid <- expand.grid(
  prefix = c('', '-', '+', 'RMB', '-RMB+', '(', '(-'),
  body = c('12', '1,234.5', '.2', '1e309', '1e308', '1 2', '１２', 'bad'),
  suffix = c('', '万', '亿元', '%', '万%', ')', '元)'),
  stringsAsFactors = FALSE)
x <- c(do.call(paste0, grid), NA, '', 'NA')
names(x) <- seq_along(x)
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  for (input in list(x, factor(x), rep(x, 3L), numeric(), c(Inf, NaN, NA, -2)))
    stopifnot(identical(suppressWarnings(old(input)), suppressWarnings(new(input))))
  fixtures <- read.delim(paste0('tests/testthat/fixtures/', kind, '-cases.tsv'),
    colClasses = 'character', na.strings = character(), fileEncoding = 'UTF-8')$input
  stopifnot(identical(suppressWarnings(old(fixtures)), suppressWarnings(new(fixtures))))
  message_for <- function(fun) tryCatch(fun(x, strict = TRUE), error = conditionMessage)
  stopifnot(identical(message_for(old), message_for(new)))
}
for (unit in c('元', '千元', '万', '亿元', '万亿'))
  stopifnot(identical(suppressWarnings(parse_cn_number(x, unit = unit)),
    suppressWarnings(candidate$parse_cn_number(x, unit = unit))))
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  for (shape in c('distinct', 'mixed')) {
    x <- if (shape == 'distinct') paste0(seq_len(100000L), '万') else
      rep(c('１２．５％', '(￥3万)', '1,234.5万', '1e-3', 'NA', 'bad'), length.out = 100000L)
    if (kind == 'quantity' && shape == 'distinct') x <- paste0('约', x)
    stopifnot(identical(suppressWarnings(old(x)), suppressWarnings(new(x))))
    cat(kind, shape, 'old/new median seconds:',
      median(replicate(3, system.time(suppressWarnings(old(x)))[['elapsed']])),
      median(replicate(3, system.time(suppressWarnings(new(x)))[['elapsed']])), '\n')
  }
}
cat('PASS: all values, names, problem attributes and strict messages agree\n')
