args <- commandArgs(trailingOnly=TRUE)
if (length(args)) .libPaths(c(args[[1]], .libPaths()))
library(cncleanr)
# Synthetic stress cases, not additional real-data coverage.
repeated <- rep(c('3万', '1.5%', 'bad', '暂无'), 25000L)
gold <- rep(c(30000, .015, NA_real_, NA_real_), 25000L)
number <- suppressWarnings(parse_cn_number(repeated))
quantity <- suppressWarnings(parse_cn_quantity(repeated))
ranges <- suppressWarnings(parse_cn_range(repeated))
bad <- seq.int(3L, length(repeated), by=4L)
stopifnot(isTRUE(all.equal(as.numeric(number), gold)),
          isTRUE(all.equal(quantity$value, gold)),
          isTRUE(all.equal(ranges$lower, gold)),
          isTRUE(all.equal(ranges$upper, gold)))
for (parsed in list(number, quantity, ranges)) {
  stopifnot(identical(cn_problems(parsed)$index, bad))
}
distinct <- as.character(seq_len(20000L))
stopifnot(identical(parse_cn_number(distinct), as.double(seq_len(20000L))))
long <- paste0('3万', strrep('x', 10000L))
for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
  result <- suppressWarnings(parser(c('2万', long, '4万')))
  stopifnot(identical(cn_problems(result)$index, 2L))
}
cat('PASS: 100000 mixed cells across three parsers, 20000 distinct numbers, long invalid input\n')
