# Compare working-tree range code with an installed, unchanged 0.2.7 baseline.
# Run from the repository root; no package files are modified.
args <- commandArgs(trailingOnly=TRUE)
.libPaths(c(if (length(args)) args[[1]] else 'outputs/validation-2026-10-08/library', .libPaths()))
library(cncleanr)
baseline <- parse_cn_range
source('R/parse-cn-range.R', encoding='UTF-8')
environment(parse_cn_range) <- asNamespace('cncleanr')
cases <- list(
  empty=character(), missing=c('暂无', NA_character_, '-'),
  mixed=c('3万', '>=3万', '>3万', '<=3万', '<3万', '约3万',
          '3-5万', '5-3万', '1e-3-2e-3', '20％～30％以上', '1 2', 'bad'),
  factor=factor(c('3万', 'bad')), numeric=c(Inf, -Inf, NA_real_, NaN),
  intervals=paste0(seq_len(1000L), '-', seq_len(1000L)+1L, '万')
)
for (x in cases) {
  stopifnot(identical(suppressWarnings(baseline(x)),
                      suppressWarnings(parse_cn_range(x))))
}
for (n in c(10000L, 100000L)) {
  x <- paste0(seq_len(n), '万')
  expected <- as.double(seq_len(n))*10000
  actual <- parse_cn_range(x)
  stopifnot(identical(actual$lower, expected), identical(actual$upper, expected),
            all(actual$lower_inclusive), all(actual$upper_inclusive))
  cat(n, 'new median seconds:',
      median(replicate(3, system.time(parse_cn_range(x))[['elapsed']])), '\n')
  # Do not repeat the known slow baseline at 100k in the everyday comparison.
  if (n == 10000L) {
    stopifnot(identical(actual, baseline(x)))
    cat(n, 'baseline median seconds:',
        median(replicate(3, system.time(baseline(x))[['elapsed']])), '\n')
  }
}
cat('PASS: baseline equivalence and independent point-range expectations\n')
