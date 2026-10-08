# Run after the Python extraction; use the installed GitHub 0.2.6 release.
.libPaths(c('outputs/release-0.2.6/library', .libPaths()))
library(cncleanr)
stopifnot(as.character(packageVersion('cncleanr')) == '0.2.6')
root <- 'outputs/multi-source-audit'
cases <- read.delim(file.path(root, 'cases.tsv'), quote = '"',
                   fileEncoding = 'UTF-8', stringsAsFactors = FALSE,
                   na.strings = character(), colClasses = 'character')
expected <- suppressWarnings(as.double(cases$expected))
parsed <- suppressWarnings(parse_cn_quantity(cases$input))
failed <- cn_problems(parsed)$index
cases$actual <- parsed$value
cases$actual_qualifier <- parsed$qualifier
cases$reason <- ''
cases$reason[failed] <- cn_problems(parsed)$reason
ranges <- suppressWarnings(parse_cn_range(cases$input))
close <- !is.na(parsed$value) & !is.na(expected) &
  abs(parsed$value - expected) <= pmax(1, abs(expected))*1e-12
cases$outcome <- ifelse(cases$status %in% c('review', 'range'), 'manual_review',
  ifelse(cases$status == 'missing',
    ifelse(is.na(parsed$value) & !seq_len(nrow(cases)) %in% failed, 'missing_ok', 'wrong'),
    ifelse(seq_len(nrow(cases)) %in% failed, 'rejected',
      ifelse(close & parsed$qualifier == cases$qualifier, 'correct', 'wrong'))))
interval <- cases$status == 'range'
range_ok <- !is.na(ranges$lower) & !is.na(ranges$upper) &
  abs(ranges$lower - suppressWarnings(as.double(cases$lower))) <= 1e-12 &
  abs(ranges$upper - suppressWarnings(as.double(cases$upper))) <= 1e-12 &
  ranges$lower_inclusive & ranges$upper_inclusive
cases$outcome[interval] <- ifelse(range_ok[interval], 'range_correct',
  ifelse(is.na(ranges$lower[interval]), 'range_rejected', 'range_wrong'))
print(table(cases$source, cases$outcome))
print(table(cases$source[!duplicated(cases[c('source', 'input')])],
            cases$outcome[!duplicated(cases[c('source', 'input')])]))
print(cases[cases$outcome %in% c('wrong', 'rejected', 'manual_review'),
            c('source', 'row', 'input', 'expected', 'actual', 'reason')])
write.table(cases, file.path(root, 'results.tsv'), sep='\t',
            row.names=FALSE, fileEncoding='UTF-8')
stopifnot(!anyNA(cases$outcome),
          !any(cases$outcome %in% c('wrong', 'rejected', 'range_rejected', 'range_wrong')))
# All three functions should preserve these ordinary measurement cells.
bird <- cases$source == 'penguins'
stopifnot(all(cases$outcome[bird] %in% c('correct', 'missing_ok')))
number <- parse_cn_number(cases$input[bird])
ranges <- parse_cn_range(cases$input[bird])
stopifnot(isTRUE(all.equal(as.numeric(number), expected[bird])),
          isTRUE(all.equal(ranges$lower, expected[bird])),
          isTRUE(all.equal(ranges$upper, expected[bird])))
cat('PASS: measurement cells agree across all three parsers\n')
# The package parses fields, not free-text abstracts.
abstracts <- read.delim(file.path(root, 'csl.tsv'), header=FALSE, quote='',
                       fileEncoding='UTF-8', stringsAsFactors=FALSE)$V2
full <- suppressWarnings(parse_cn_number(abstracts))
cat('Whole abstracts accepted:', sum(!is.na(full)), '/', length(full), '\n')
# Independently hand-checked lexical examples selected from the source spans.
manual <- c('64.18%', '约15％左右', '20%-30%', '17．65％～58．82％', '31%±16%')
stopifnot(all(manual %in% cases$input))
stopifnot(identical(parse_cn_number(manual[1]), .6418))
intervals <- parse_cn_range(manual[3:4])
stopifnot(isTRUE(all.equal(intervals$lower, c(.2, .1765))),
          isTRUE(all.equal(intervals$upper, c(.3, .5882))))
stopifnot(nrow(cn_problems(suppressWarnings(parse_cn_quantity(manual[2])))) == 1L,
          nrow(cn_problems(suppressWarnings(parse_cn_range(manual[5])))) == 1L)
cat('PASS: five hand-reviewed examples, including safe rejections\n')
# Recheck the previous financial sample against the installed release too.
finance <- read.delim('outputs/real-data-audit/spans.tsv', quote='"',
                     fileEncoding='UTF-8', stringsAsFactors=FALSE)
gold <- as.double(finance$expected)
actual <- suppressWarnings(parse_cn_quantity(finance$input))
valid <- finance$status == 'valid'
stopifnot(all(abs(actual$value[valid] - gold[valid]) <=
                pmax(1, abs(gold[valid]))*1e-12),
          identical(actual$qualifier[valid], finance$qualifier[valid]),
          all(is.na(actual$value[!valid])),
          setequal(cn_problems(actual)$index, which(!valid)))
cat('PASS: CFQA', sum(valid), 'valid spans and', sum(!valid), 'malformed spans\n')
