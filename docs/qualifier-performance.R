# Rscript docs/qualifier-performance.R [unchanged native-stage library]
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(if (length(args)) args[[1L]] else
  'outputs/native-optimization/library', .libPaths()))
library(cncleanr)
candidate <- new.env(parent = asNamespace('cncleanr'))
for (kind in c('number', 'quantity', 'range'))
  source(paste0('R/parse-cn-', kind, '.R'), local = candidate, encoding = 'UTF-8')
for (name in ls(candidate))
  if (is.function(candidate[[name]])) candidate[[name]] <- compiler::cmpfun(candidate[[name]])
grid <- expand.grid(
  prefix = c('', '不超过', '不高于', '不大于', '不多于', '至多', '<=', '≤', '≦',
    '不少于', '不低于', '不小于', '至少', '>=', '≥', '≧', '超过', '超出', '超',
    '大于', '高于', '多于', '>', '低于', '小于', '不足', '少于', '<',
    '大约', '约为', '大概', '约', '近', '约约', '>=约'),
  body = c('3万', '-2e-3', '50余万元', '1 2', '1 234', '１．２万', 'NA', ''),
  suffix = c('', '以上', '+', '以下', '余', '左右', '左右左右', '以上以下'),
  stringsAsFactors = FALSE)
x <- c(do.call(paste0, grid), NA, '约1\u202f234万元左右', '约1\u00a023万')
names(x) <- seq_along(x)
for (kind in c('number', 'quantity', 'range')) {
  old <- get(paste0('parse_cn_', kind))
  new <- candidate[[paste0('parse_cn_', kind)]]
  fixture <- read.delim(paste0('tests/testthat/fixtures/', kind, '-cases.tsv'),
    colClasses = 'character', na.strings = character(), fileEncoding = 'UTF-8')$input
  for (input in list(x, factor(x), fixture, c(NA, '暂无'), character(), c(Inf, NaN, NA)))
    stopifnot(identical(suppressWarnings(old(input)), suppressWarnings(new(input))))
  stopifnot(identical(suppressWarnings(old(x, na = c('约3万', '1 2'))),
    suppressWarnings(new(x, na = c('约3万', '1 2')))))
  message_for <- function(fun) tryCatch(fun(x, strict = TRUE), error = conditionMessage)
  stopifnot(identical(message_for(old), message_for(new)))
}
for (unit in c('元', '千元', '万', '亿元', '万亿'))
  stopifnot(identical(suppressWarnings(parse_cn_number(x, unit = unit)),
    suppressWarnings(candidate$parse_cn_number(x, unit = unit))))
id <- seq_len(100000L)
plain <- paste0('约', id, '万')
inequality <- paste0(rep(c('大于', '不小于', '不大于', '<', '>='), length.out = length(id)), id, '万')
suffix <- paste0(id, '万', rep(c('以上', '以下', '+', '余', '左右'), length.out = length(id)))
formatted <- paste0('约 RMB ', id, ' 万元左右')
for (shape in c('approx', 'inequality', 'suffix', 'formatted', 'repeated', 'invalid_1pct', 'invalid_10pct')) {
  x <- switch(shape, approx = plain, inequality = inequality, suffix = suffix,
    formatted = formatted, repeated = rep(inequality[1:100], 1000L), plain)
  if (grepl('invalid', shape, fixed = TRUE)) {
    rows <- seq.int(1L, length(x), by = if (shape == 'invalid_1pct') 100L else 10L)
    x[rows] <- rep(c('bad', '约3万以上'), length.out = length(rows))
  }
  old <- parse_cn_quantity
  new <- candidate$parse_cn_quantity
  stopifnot(identical(suppressWarnings(old(x)), suppressWarnings(new(x))))
  repeats <- if (shape == 'repeated') 10L else 1L
  timing <- function(fun) median(replicate(3,
    system.time(for (j in seq_len(repeats)) suppressWarnings(fun(x)))[['elapsed']] / repeats))
  cat(shape, '100000 cells; unique:', length(unique(x)), 'old/new seconds:',
    timing(old), timing(new), '\n')
}
cat('PASS: all parsers, values, qualifiers, names, errors and custom missing markers agree\n')
