# Run: python docs/real-data-audit.py
#      Rscript --vanilla docs/real-data-audit.R
# Source package functions directly: no installed devtools/testthat required.
for (file in list.files('R', pattern = '[.]R$', full.names = TRUE)) source(file)
root <- 'outputs/real-data-audit'
cases <- read.delim(file.path(root, 'spans.tsv'), quote = '"',
                   fileEncoding = 'UTF-8', stringsAsFactors = FALSE)
expected <- as.double(cases$expected)
result <- suppressWarnings(parse_cn_quantity(cases$input))
failed <- cn_problems(result)$index
cases$actual <- result$value
cases$actual_qualifier <- result$qualifier
cases$reason <- NA_character_
cases$reason[failed] <- cn_problems(result)$reason
close <- !is.na(result$value) & !is.na(expected) &
  abs(result$value - expected) <= pmax(1, abs(expected)) * 1e-12
cases$outcome <- ifelse(is.na(result$value), 'rejected',
                       ifelse(close & result$qualifier == cases$qualifier,
                              'correct', 'wrong_acceptance'))
write.table(cases, file.path(root, 'results.tsv'), sep = '\t',
            row.names = FALSE, fileEncoding = 'UTF-8')
print(table(cases$status, cases$outcome))
print(table(cases$unit, cases$outcome))
print(cases[cases$outcome != 'correct', c('id', 'input', 'expected', 'actual', 'reason')])
# Complete answers are out of scope and should be visibly rejected.
answers <- jsonlite::fromJSON(file.path(root, 'cfqa.json'))[['答案']]
full <- suppressWarnings(parse_cn_number(answers))
cat('Complete answers accepted:', sum(!is.na(full)), '/', length(full), '\n')
jobs <- read.csv(file.path(root, 'jobs.csv'), fileEncoding = 'UTF-8')
cat('Job rows:', nrow(jobs), '; nonmissing salaries:',
    sum(!is.na(jobs$salary) & nzchar(jobs$salary)), '\n')
# Sample by distinct raw inputs, so repetitions cannot inflate the verdict.
distinct <- cases[!duplicated(cases$input), ]
cat('Distinct span outcomes:\n')
print(table(distinct$outcome))
# Independently map Decimal gold values/qualifiers to interval expectations.
ranges <- suppressWarnings(parse_cn_range(cases$input))
lower <- upper <- expected
li <- ui <- rep(TRUE, nrow(cases))
above <- cases$qualifier %in% c('greater_than', 'at_least')
below <- cases$qualifier %in% c('less_than', 'at_most')
upper[above] <- Inf
ui[above] <- FALSE
li[cases$qualifier == 'greater_than'] <- FALSE
lower[below] <- -Inf
li[below] <- FALSE
ui[cases$qualifier == 'less_than'] <- FALSE
eligible <- cases$status == 'valid' & cases$qualifier != 'approx'
accepted <- !is.na(ranges$lower) & !is.na(ranges$upper)
same <- function(x, y) (x == y) | (is.finite(x) & is.finite(y) &
  abs(x-y) <= pmax(1, abs(y))*1e-12)
range_correct <- eligible & accepted & same(ranges$lower, lower) &
  same(ranges$upper, upper) & ranges$lower_inclusive == li &
  ranges$upper_inclusive == ui
cat('Range eligible:', sum(eligible), '; correct:', sum(range_correct, na.rm=TRUE),
    '; rejected:', sum(eligible & !accepted),
    '; wrong acceptances:', sum(accepted & !range_correct, na.rm=TRUE), '\n')
# Hand-reviewed source spans, literal expected numbers: no extraction regex.
manual <- data.frame(
  input = c('6.38%', '210935262.33元', '785,646,432.47元',
            '-76,411,324.08元', '45000万元', '2.27万亿', '4.91 万亿',
            '约119.75万', '30%左右', '超过2,500万', '5000 万元以上',
            '不超过人民币2.5亿元'),
  value = c(.0638, 210935262.33, 785646432.47, -76411324.08,
            450000000, 2270000000000, 4910000000000, 1197500,
            .3, 25000000, 50000000, 250000000),
  qualifier = c(rep('exact', 7), 'approx', 'approx', 'greater_than',
                'at_least', 'at_most'))
stopifnot(all(manual$input %in% cases$input))
gold <- parse_cn_quantity(manual$input)
stopifnot(isTRUE(all.equal(gold$value, manual$value)),
          identical(gold$qualifier, manual$qualifier))
cat('Manually reviewed source cases:', nrow(manual), 'passed\n')
cat('Repeated 10000 range elapsed:',
    system.time(parse_cn_range(rep('3万-5万', 10000)))[['elapsed']], '\n')
