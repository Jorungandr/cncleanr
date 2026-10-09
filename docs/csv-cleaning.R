# Rscript docs/csv-cleaning.R [optional-library-path]
# Synthetic example; each run writes only to its own temporary directory.
args <- commandArgs(trailingOnly=TRUE)
if (length(args)) .libPaths(c(args[[1]], .libPaths()))
library(cncleanr)
output <- tempfile('cncleanr-csv-')
dir.create(output)
original <- data.frame(
  id=c('0001', '0002', '0003'),
  amount=c('316', '1 2', '暂无'),
  headcount=c('10536', 'bad', '0007'),
  share=c('11.81', '5%', '-'), stringsAsFactors=FALSE
)
input <- file.path(output, 'input.csv')
write.csv(original, input, row.names=FALSE, fileEncoding='UTF-8')
raw <- read.csv(input, colClasses='character', na.strings=character(),
                check.names=FALSE, fileEncoding='UTF-8')
stopifnot(identical(raw, original))
cleaned <- raw
problem_parts <- list()
for (field in c('amount', 'headcount', 'share')) {
  # The monetary column is in ten thousand yuan. Headcounts have no multiplier.
  # Share is defined as percentage points, so bare values are given an explicit %.
  text <- raw[[field]]
  if (field == 'share') {
    bare <- grepl('^[+-]?[0-9]+([.][0-9]+)?$', text)
    text[bare] <- paste0(text[bare], '%')
  }
  parsed <- suppressWarnings(parse_cn_number(text,
    unit=if (field == 'amount') '万元' else NULL))
  cleaned[[paste0(field, '_value')]] <- as.numeric(parsed)
  problems <- cn_problems(parsed)
  if (nrow(problems)) {
    rows <- problems$index
    problem_parts[[field]] <- data.frame(
      source_row=rows, id=raw$id[rows], field=field,
      original=raw[[field]][rows], reason=problems$reason,
      stringsAsFactors=FALSE
    )
  }
}
review <- do.call(rbind, problem_parts)
rownames(review) <- NULL
cleaned$amount_unit <- 'yuan'
cleaned$headcount_unit <- 'persons'
cleaned$share_unit <- 'proportion'
stopifnot(identical(cleaned$id, c('0001', '0002', '0003')),
  isTRUE(all.equal(cleaned$amount_value, c(3160000, NA_real_, NA_real_))),
  isTRUE(all.equal(cleaned$headcount_value, c(10536, NA_real_, 7))),
  isTRUE(all.equal(cleaned$share_value, c(.1181, .05, NA_real_))),
  identical(review$source_row, c(2L, 2L)),
  identical(review$field, c('amount', 'headcount')),
  identical(review$original, c('1 2', 'bad')))
write.csv(cleaned, file.path(output, 'cleaned.csv'), row.names=FALSE,
          na='', fileEncoding='UTF-8')
write.csv(review, file.path(output, 'problems.csv'), row.names=FALSE,
          fileEncoding='UTF-8')
# Read exported text without automatic type conversion or implicit missing markers.
roundtrip <- read.csv(file.path(output, 'cleaned.csv'), colClasses='character',
                     na.strings=character(), fileEncoding='UTF-8')
stopifnot(identical(roundtrip[names(raw)], raw),
          isTRUE(all.equal(as.double(roundtrip$share_value), cleaned$share_value)),
          identical(read.csv(file.path(output, 'problems.csv'),
            colClasses='character', na.strings=character(), fileEncoding='UTF-8')$original,
            review$original))
print(cleaned)
print(review)
cat('PASS: import, parsing, review indices and CSV round-trip\n')
cat('Temporary output directory:', output, '\n')
