# Compare working-tree code with an unchanged installed quantity parser.
# Rscript docs/quantity-performance.R [baseline-library]
args <- commandArgs(trailingOnly=TRUE)
.libPaths(c(if (length(args)) args[[1]] else 'outputs/range-endpoint-optimization/library', .libPaths()))
library(cncleanr)
baseline <- parse_cn_quantity
candidate <- new.env(parent=asNamespace('cncleanr'))
source('R/parse-cn-quantity.R', local=candidate, encoding='UTF-8')
parser <- candidate$parse_cn_quantity
fixture <- read.delim('tests/testthat/fixtures/quantity-cases.tsv',
  colClasses='character', na.strings=character(), fileEncoding='UTF-8')$input
for (x in list(fixture, rep(fixture, 20L), factor(fixture), character(),
              c(Inf, -Inf, NA_real_, NaN),
              setNames(c('bad', '约1 2', '约12', 'bad', NA, '约15％左右'), letters[1:6]))) {
  stopifnot(identical(suppressWarnings(baseline(x)), suppressWarnings(parser(x))))
}
custom <- rep(c('保密', '约3万', 'bad', '约3万以上'), 100L)
stopifnot(identical(suppressWarnings(baseline(custom, na='保密')),
                    suppressWarnings(parser(custom, na='保密'))))
strict_message <- function(fun) tryCatch(fun(custom, na='保密', strict=TRUE),
                                        error=conditionMessage)
stopifnot(identical(strict_message(baseline), strict_message(parser)))
grid <- expand.grid(
  prefix=c('', '约', '近', '大于', '不小于', '不大于', '至少', '<', '>='),
  body=c('3万', '50余万元', '1 2', 'NA', '-2e-3', ''),
  suffix=c('', '左右', '+', '以上', '以下', '余'), stringsAsFactors=FALSE)
combinations <- do.call(paste0, grid)
stopifnot(identical(suppressWarnings(baseline(combinations)),
                    suppressWarnings(parser(combinations))))
for (kind in c('repeated', 'distinct')) {
  x <- if (kind == 'repeated') rep(c('约3万', '10万+', '50余万元', 'bad'), 25000L)
       else paste0('约', seq_len(100000L), '万')
  stopifnot(identical(suppressWarnings(baseline(x)), suppressWarnings(parser(x))))
  cat(kind, 'baseline median seconds:',
      median(replicate(3, system.time(suppressWarnings(baseline(x)))[['elapsed']])), '\n')
  # Aggregate fast calls to avoid reporting a timer-resolution zero as infinite speed.
  repeats <- if (kind == 'repeated') 20L else 1L
  elapsed <- replicate(3, system.time(for (j in seq_len(repeats))
    suppressWarnings(parser(x)))[['elapsed']] / repeats)
  cat(kind, 'candidate median seconds per call:', median(elapsed), '\n')
}
cat('PASS: values, qualifiers, all problem attributes and strict messages agree\n')
