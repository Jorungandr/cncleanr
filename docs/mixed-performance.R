# Rscript docs/mixed-performance.R [unchanged baseline library]
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(if (length(args)) args[[1L]] else
  'outputs/qualifier-optimization/library', .libPaths()))
library(cncleanr)
candidate <- new.env(parent = asNamespace('cncleanr'))
for (kind in c('number', 'quantity', 'range'))
  source(paste0('R/parse-cn-', kind, '.R'), local = candidate, encoding = 'UTF-8')
for (name in ls(candidate))
  if (is.function(candidate[[name]])) candidate[[name]] <- compiler::cmpfun(candidate[[name]])

x <- c('3万', '-0%', '.2', NA, '１２．５％', '(RMB3万)',
       '1 234万', '1 2', 'bad', '1e308万', '3万%', 'NA')
names(x) <- seq_along(x)
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  fixture <- read.delim(paste0('tests/testthat/fixtures/', kind, '-cases.tsv'),
    colClasses = 'character', na.strings = character(), fileEncoding = 'UTF-8')$input
  for (input in list(x, factor(x), fixture, character(), c(Inf, NaN, NA)))
    stopifnot(identical(suppressWarnings(old(input)), suppressWarnings(new(input))))
  stopifnot(identical(suppressWarnings(old(x, na = c('３万', '1 2'))),
    suppressWarnings(new(x, na = c('３万', '1 2')))))
  strict_message <- function(fun) tryCatch(fun(x, strict = TRUE), error = conditionMessage)
  stopifnot(identical(strict_message(old), strict_message(new)))
}
for (unit in c('元', '千元', '万', '亿', '万亿'))
  stopifnot(identical(suppressWarnings(parse_cn_number(x, unit = unit)),
    suppressWarnings(candidate$parse_cn_number(x, unit = unit))))

plain <- paste0(seq_len(100000L), '万')
samples <- list(plain = plain)
for (share in c(.01, .1, .5, 1)) {
  rows <- seq_len(as.integer(length(plain) * share))
  formatted <- invalid <- plain
  formatted[rows] <- paste0('RMB ', plain[rows])
  invalid[rows] <- 'bad'
  samples[[paste0('formatted_', share)]] <- formatted
  samples[[paste0('invalid_', share)]] <- invalid
}
for (name in names(samples)) {
  input <- samples[[name]]
  stopifnot(identical(suppressWarnings(parse_cn_number(input)),
    suppressWarnings(candidate$parse_cn_number(input))))
  timing <- function(fun) median(replicate(3,
    system.time(for (i in seq_len(5L)) suppressWarnings(fun(input)))[['elapsed']] / 5))
  cat(name, 'baseline/candidate seconds:', timing(parse_cn_number),
    timing(candidate$parse_cn_number), '\n')
}
cat('PASS: values, names, missing markers, problems and strict errors match\n')
