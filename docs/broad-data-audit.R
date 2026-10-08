args <- commandArgs(trailingOnly=TRUE)
.libPaths(c(if (length(args)) args[[1]] else 'outputs/release-0.2.7/library', .libPaths()))
library(cncleanr)
stopifnot(as.character(packageVersion('cncleanr')) == '0.2.7')
root <- 'outputs/broad-data-audit'
x <- read.delim(file.path(root, 'cases.tsv'), colClasses='character',
                na.strings=character(), fileEncoding='UTF-8')
gold <- suppressWarnings(as.double(x$expected))
actual <- suppressWarnings(parse_cn_number(x$input))
# Only monetary fields receive the documented column-level monetary unit.
money <- x$source == 'TW:tourism' & x$unit == '萬元'
actual[money] <- suppressWarnings(parse_cn_number(x$input[money], unit='万元'))
problems <- cn_problems(suppressWarnings(parse_cn_number(x$input)))$index
equal <- function(a, b) !is.na(a) & !is.na(b) & abs(a-b) <= pmax(1, abs(b))*1e-12
x$outcome <- ifelse(x$status == 'numeric', ifelse(equal(actual,gold), 'correct','wrong'),
  ifelse(x$status == 'missing', ifelse(is.na(actual) & !seq_len(nrow(x)) %in% problems,'missing_ok','wrong'),
    ifelse(is.na(actual) & seq_len(nrow(x)) %in% problems,'review_rejected','review_accepted')))
interval <- x$status == 'range'
r <- suppressWarnings(parse_cn_range(x$input[interval]))
x$outcome[interval] <- ifelse(equal(r$lower,gold[interval]) &
  equal(r$upper,as.double(x$upper[interval])) & r$lower_inclusive & r$upper_inclusive,'range_correct','wrong')
print(with(x, table(source,outcome)))
write.table(x, file.path(root,'results-0.2.7.tsv'), sep='\t',row.names=FALSE,fileEncoding='UTF-8')
print(x[x$outcome %in% c('wrong','review_accepted'),c('source','row','field','input','outcome')])
stopifnot(!anyNA(x$outcome), !any(x$outcome %in% c('wrong','review_accepted')))
cat('PASS: raw cells and separately labelled derived salary intervals\n')
