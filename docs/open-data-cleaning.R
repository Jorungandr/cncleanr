# Run from the repository root after installing cncleanr:
# Rscript docs/open-data-cleaning.R [optional-library-path]
args <- commandArgs(trailingOnly=TRUE)
if (length(args)) .libPaths(c(args[[1]], .libPaths()))
library(cncleanr)

# Small, explicitly selected cells, not an entire government data snapshot.
raw <- data.frame(
  source_row=1:6,
  text=c('10,536', '-', '#VALUE!', '未統計',
         '27,091(外國跑者3,249人)', '活動仍辦理中'),
  unit='persons', stringsAsFactors=FALSE
)
# An explicit project decision; do not silently classify every rejection as missing.
missing_markers <- c('', '-', '未統計')
parsed <- suppressWarnings(parse_cn_number(raw$text, na=missing_markers))
problems <- cn_problems(parsed)
cleaned <- raw
cleaned$value <- as.numeric(parsed)
cleaned$status <- ifelse(is.na(cleaned$value), 'missing', 'parsed')
cleaned$status[problems$index] <- 'needs_review'
review <- cbind(raw[problems$index, ], reason=problems$reason)

stopifnot(isTRUE(all.equal(cleaned$value, c(10536, rep(NA_real_, 5)))),
          identical(problems$index, c(3L, 5L, 6L)),
          identical(cleaned$status,
                    c('parsed', 'missing', 'needs_review', 'missing',
                      'needs_review', 'needs_review')))
print(cleaned)
print(review)

# Synthetic unit examples, not additional observations from the source dataset.
units <- data.frame(field=c('population', 'share', 'benefit'),
                    text=c('1.5', '11.81', '316'),
                    source_unit=c('thousand persons', 'percent', 'ten thousand yuan'))
units$value <- c(parse_cn_number(units$text[1]),
                 parse_cn_number(units$text[2]),
                 parse_cn_number(units$text[3], unit='万元'))
units$output_unit <- c('thousand persons', 'percent', 'yuan')
stopifnot(isTRUE(all.equal(units$value, c(1.5, 11.81, 3160000))))
# Conversion to a proportion is a separate, explicit caller decision.
proportion <- units$value[2] / 100
stopifnot(isTRUE(all.equal(proportion, .1181)))
print(units)
# No automatic CSV export: choose output paths explicitly to avoid overwriting files.
