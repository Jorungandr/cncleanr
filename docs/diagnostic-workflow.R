# Runnable compatibility example; CI loads the candidate package first.
raw <- c('bad', '2万', 'wrong', '1万')
parsed <- suppressWarnings(parse_cn_number(raw))
rows <- c(3L, 2L, 1L, 3L)
selected <- cn_subset(parsed, rows)
problems <- cn_problems(selected)
stopifnot(identical(names(problems), c('index', 'value', 'reason')),
          identical(problems$index, c(1L, 3L, 4L)),
          identical(problems$value, c('wrong', 'bad', 'wrong')),
          identical(problems$value, raw[rows[problems$index]]),
          identical(class(selected), 'numeric'))
sorted <- cn_subset(parsed, order(parsed, na.last = TRUE))
stopifnot(identical(cn_problems(sorted)$index, 3:4))
clean <- cn_subset(parsed, !is.na(parsed))
stopifnot(identical(clean, c(20000, 10000)), nrow(cn_problems(clean)) == 0L)
quantity <- suppressWarnings(parse_cn_quantity(raw))
stopifnot(identical(class(cn_subset(quantity, rows)), 'data.frame'))
bad <- rawToChar(as.raw(c(0xef, 0xbc)))
Encoding(bad) <- 'UTF-8'
message <- tryCatch(parse_cn_number(c('1', '1', bad)), error = conditionMessage)
stopifnot(grepl('Input `x` at position 3', message, fixed = TRUE))
message <- tryCatch(parse_cn_number('1', na = c('', bad)), error = conditionMessage)
stopifnot(grepl('Input `na` at position 2', message, fixed = TRUE))
cat('PASS: subset/reorder diagnostics and original encoding positions\n')
