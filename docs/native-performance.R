# Rscript docs/native-performance.R [candidate DLL] [unchanged R baseline library]
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(if (length(args) > 1L) args[[2L]] else
  'outputs/number-optimization/library', .libPaths()))
library(cncleanr)
dll_path <- if (length(args)) args[[1L]] else list.files(
  'outputs/native-optimization/library/cncleanr/libs', recursive = TRUE, full.names = TRUE)
if (!length(args)) dll_path <- dll_path[
  basename(dll_path) == paste0('cncleanr', .Platform$dynlib.ext)]
stopifnot(length(dll_path) == 1L)
dll <- dyn.load(dll_path)
symbol <- getNativeSymbolInfo('simple_numbers', dll)
candidate <- new.env(parent = asNamespace('cncleanr'))
candidate$C_simple_numbers <- symbol
for (kind in c('number', 'quantity', 'range'))
  source(paste0('R/parse-cn-', kind, '.R'), local = candidate, encoding = 'UTF-8')
for (name in ls(candidate))
  if (is.function(candidate[[name]])) candidate[[name]] <- compiler::cmpfun(candidate[[name]])
grid <- expand.grid(prefix = c('', '-', '+', '(', 'RMB', '约'),
  body = c('0', '.2', '.', '1.', '1e309', '1e308', '1e-999', '1,234',
           '1 2', '１２．５', '0x12', 'NA', 'bad'),
  suffix = c('', '万', '亿元', '千元', '%', '万%', ')', '左右'),
  stringsAsFactors = FALSE)
x <- c(do.call(paste0, grid), NA, '', '1万亿', '-0', '-0%', '.e2')
names(x) <- seq_along(x)
# Check accepted cells directly: whole-batch fallback must not hide a false match.
fast <- .Call(symbol, x, NA_real_)
handled <- which(!is.na(fast))
reference <- suppressWarnings(parse_cn_number(x))
stopifnot(identical(fast[handled], as.numeric(reference)[handled]),
  !any(handled %in% cn_problems(reference)$index))
set.seed(42)
random <- sprintf('%.17g', runif(10000, -1e200, 1e200))
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  fixture <- read.delim(paste0('tests/testthat/fixtures/', kind, '-cases.tsv'),
    colClasses = 'character', na.strings = character(), fileEncoding = 'UTF-8')$input
  for (input in list(x, factor(x), fixture, random, numeric(), c(Inf, NaN, NA)))
    stopifnot(identical(suppressWarnings(old(input)), suppressWarnings(new(input))))
  strict_message <- function(fun) tryCatch(fun(x, strict = TRUE), error = conditionMessage)
  stopifnot(identical(strict_message(old), strict_message(new)))
}
for (unit in c('元', '千元', '万', '亿元', '万亿'))
  stopifnot(identical(suppressWarnings(parse_cn_number(x, unit = unit)),
    suppressWarnings(candidate$parse_cn_number(x, unit = unit))))
stopifnot(identical(parse_cn_number(c('3万', '2'), na = '3万'),
  candidate$parse_cn_number(c('3万', '2'), na = '3万')))
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  for (size in c(100000L, 1000000L)) {
    x <- paste0(seq_len(size), '万')
    if (kind == 'quantity') x <- paste0('约', x)
    stopifnot(identical(suppressWarnings(old(x)), suppressWarnings(new(x))))
    # Aggregate fast calls rather than interpreting timer-resolution zero as free.
    repeats <- if (kind == 'number' && size == 100000L) 20L else 1L
    timing <- function(fun) median(replicate(3,
      system.time(for (j in seq_len(repeats)) suppressWarnings(fun(x)))[['elapsed']] / repeats))
    cat(kind, size, 'R/native median seconds:', timing(old), timing(new), '\n')
  }
}
cat('PASS: native outputs and error attributes match the R baseline\n')
