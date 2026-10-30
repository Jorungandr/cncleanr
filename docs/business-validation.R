# Rscript docs/business-validation.R <installed-library> [cases.csv output-directory]
# End-to-end validation: canonical text import -> parse -> review -> CSV/RDS.
source('docs/audit-setup.R')
stopifnot(length(args) %in% c(1L, 3L))
root <- if (length(args) == 3L) args[[3L]] else 'outputs/business-validation-2026-10-30'
input <- if (length(args) == 3L) args[[2L]] else file.path(root, 'cases.csv')
dir.create(root, recursive = TRUE, showWarnings = FALSE)
x <- read.csv(input, colClasses = 'character',
              na.strings = character(), check.names = FALSE, fileEncoding = 'UTF-8')
stopifnot(!anyDuplicated(x$case_id), nrow(x) > 0L)
x$value <- x$upper <- NA_real_
x$qualifier <- NA_character_
x$lower_inclusive <- x$upper_inclusive <- NA
x$reason <- ''
x$parser_failed <- FALSE
pending <- which(x$expected_status != 'business_review')
groups <- split(pending, interaction(x$parser[pending], x$parser_unit[pending], drop = TRUE))
parsed_objects <- list()
for (indices in groups) {
  parser <- get(paste0('parse_cn_', x$parser[indices[1L]]), asNamespace('cncleanr'))
  unit <- x$parser_unit[indices[1L]]
  result <- suppressWarnings(parser(x$parse_input[indices], unit = if (unit == '') NULL else unit))
  parsed_objects[[x$case_id[indices[1L]]]] <- list(case_id = x$case_id[indices], result = result)
  if (is.data.frame(result) && 'lower' %in% names(result)) {
    x$value[indices] <- result$lower
    x$upper[indices] <- result$upper
    x$lower_inclusive[indices] <- result$lower_inclusive
    x$upper_inclusive[indices] <- result$upper_inclusive
  } else {
    x$value[indices] <- if (is.data.frame(result)) result$value else as.numeric(result)
    if (is.data.frame(result)) x$qualifier[indices] <- result$qualifier
  }
  problems <- cn_problems(result)
  failed <- indices[problems$index]
  x$parser_failed[failed] <- TRUE
  x$reason[failed] <- problems$reason
}
equal <- function(actual, expected) {
  gold <- suppressWarnings(as.double(expected))
  !is.na(actual) & !is.na(gold) & abs(actual - gold) <= 1e-12 * pmax(1, abs(gold))
}
ok <- equal(x$value, x$expected_value) & !x$parser_failed
quantity <- x$parser == 'quantity'
ok[quantity] <- ok[quantity] & !is.na(x$qualifier[quantity]) &
  x$qualifier[quantity] == x$expected_qualifier[quantity]
range <- x$parser == 'range'
ok[range] <- ok[range] & equal(x$upper[range], x$expected_upper[range]) &
  !is.na(x$lower_inclusive[range]) & x$lower_inclusive[range] &
  !is.na(x$upper_inclusive[range]) & x$upper_inclusive[range]
x$outcome <- 'wrong'
x$outcome[x$expected_status == 'parsed' & ok] <- 'correct_parse'
x$outcome[x$expected_status == 'missing' & is.na(x$value) & !x$parser_failed] <- 'missing_ok'
x$outcome[x$expected_status == 'reject' & is.na(x$value) & x$parser_failed] <- 'correct_rejection'
x$outcome[x$expected_status == 'business_review'] <- 'business_review_not_parsed'
x$status <- ifelse(x$outcome == 'correct_parse', 'parsed',
  ifelse(x$outcome == 'missing_ok', 'missing', 'needs_review'))
x$reason[x$expected_status == 'business_review'] <- x$review_note[x$expected_status == 'business_review']
review <- x[x$status == 'needs_review', c('case_id', 'domain', 'source', 'source_row',
  'record_id', 'field', 'raw_input', 'parse_input', 'source_unit', 'pay_period',
  'transformation', 'outcome', 'reason')]
rownames(review) <- NULL
print(with(x, table(domain, outcome)))
stopifnot(!anyNA(x$outcome), !any(x$outcome == 'wrong'))
for (domain in unique(x$domain)) {
  for (kind in c('cleaned', 'review')) {
    data <- if (kind == 'cleaned') x[x$domain == domain, ] else review[review$domain == domain, ]
    file <- file.path(root, paste0(domain, '-', kind, '.csv'))
    write.csv(data, file, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
    back <- read.csv(file, colClasses = 'character', na.strings = character(),
                     check.names = FALSE, fileEncoding = 'UTF-8')
    # CSV preserves the source text/provenance; binary64 tail bits use RDS below.
    for (column in names(data)[vapply(data, is.character, logical(1))]) {
      wanted <- data[[column]]
      wanted[is.na(wanted)] <- ''
      stopifnot(identical(back[[column]], wanted))
    }
    if (kind == 'cleaned') {
      for (column in c('value', 'upper')) {
        wanted <- data[[column]]
        actual <- suppressWarnings(as.double(back[[column]]))
        stopifnot(identical(is.na(actual), is.na(wanted)),
          all(equal(actual[!is.na(wanted)], wanted[!is.na(wanted)])))
      }
      for (column in c('lower_inclusive', 'upper_inclusive'))
        stopifnot(identical(as.logical(back[[column]]), data[[column]]))
    }
  }
}
saveRDS(parsed_objects, file.path(root, 'parsed-objects.rds'))
stopifnot(identical(readRDS(file.path(root, 'parsed-objects.rds')), parsed_objects))
counts <- as.data.frame(with(x, table(domain, outcome)))
write.csv(counts, file.path(root, 'counts.csv'), row.names = FALSE)
cat('PASS:', nrow(x), 'business cases; review records:', nrow(review),
    '; CSV provenance and numeric tolerance checks; exact RDS round-trip\n')
