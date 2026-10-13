test_that('explicit subsets retain, reorder and duplicate problems without new classes', {
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    result <- suppressWarnings(parser(c('bad', '2', 'wrong', '1')))
    selected <- cn_subset(result, c(3, 2, 1, 3))
    expect_identical(class(selected), class(result))
    expect_identical(cn_problems(selected)$index, c(1L, 3L, 4L))
    expect_identical(cn_problems(selected)$value, c('wrong', 'bad', 'wrong'))
    expect_identical(cn_problems(selected)$reason,
      cn_problems(result)$reason[c(2, 1, 2)])
    expect_identical(cn_problems(cn_subset(selected, c(4, 2)))$index, 1L)
    expect_identical(cn_problems(cn_subset(selected, c(4, 2)))$value, 'wrong')
    clean <- cn_subset(result, c(FALSE, TRUE, FALSE, TRUE))
    expect_equal(nrow(cn_problems(clean)), 0L)
    expect_null(attr(clean, 'problems', exact = TRUE))
    expect_null(attr(cn_subset(result, integer()), 'problems', exact = TRUE))
    expect_identical(cn_problems(cn_subset(result, c(0, -2, -4)))$index, 1:2)
    expect_identical(cn_problems(cn_subset(result))$value, c('bad', 'wrong'))
    values <- if (is.data.frame(result)) result[[1L]] else result
    sorted <- cn_subset(result, order(values, na.last = TRUE))
    expect_identical(cn_problems(sorted)$index, 3:4)
    expect_identical(cn_problems(sorted)$value, c('bad', 'wrong'))
  }
  x <- suppressWarnings(parse_cn_number(c(a = 'bad', b = '2')))
  expect_identical(names(cn_subset(x, c(2, 1, 1))), c('b', 'a', 'a'))
  expect_identical(cn_subset(parse_cn_number(c(3, 1)), c(2, 1)), c(1, 3))
  expect_equal(nrow(cn_subset(parse_cn_quantity(character()), logical())), 0L)
})

test_that('subset selection rejects ambiguous or manufactured rows', {
  x <- parse_cn_number(c('1', '2'))
  for (rows in list(NA, c(TRUE, FALSE, TRUE), TRUE, c(1, NA), 3, -3,
                   .5, Inf, 'a', factor(1), matrix(1)))
    expect_error(cn_subset(x, rows), 'rows')
  expect_error(cn_subset(x, c(-1, 2)))
  for (input in list('1', list(1), matrix(1), data.frame(a = 1)))
    expect_error(cn_subset(input, 1), 'x')
  attr(x, 'problems') <- data.frame(index = 3L, value = 'bad', reason = 'bad')
  expect_error(cn_subset(x, 1), 'stale')
})

test_that('encoding failures identify original argument positions through fallback and deduplication', {
  bad <- rawToChar(as.raw(c(0xef, 0xbc)))
  Encoding(bad) <- 'UTF-8'
  bytes <- '\xff'
  Encoding(bytes) <- 'bytes'
  for (damaged in list(bad, bytes, '\ufffe')) {
    for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
      for (strict in c(FALSE, TRUE)) {
        expect_error(parser(c('2', '2', damaged, '1'), strict = strict),
                     'Input `x` at position 3')
        expect_error(parser('1', na = c('', 'NA', damaged), strict = strict),
                     'Input `na` at position 3')
        expect_error(parser(c(rep('约2', 1100), damaged), strict = strict),
                     'Input `x` at position 1101')
      }
      input <- structure(c(1L, 1L, 2L), levels = c('2', damaged), class = 'factor')
      expect_error(parser(input), 'Input `x` at position 3')
      expect_error(parser(c(damaged, '2', damaged)), 'Input `x` at position 1')
      expect_error(parser(c('1', damaged), na = c('', damaged)), 'Input `(x|na)` at position 2')
    }
  }
})

test_that('ordinary diagnostics and valid encodings remain unchanged', {
  expect_error(parse_cn_number('bad', strict = TRUE), 'First problem: value does not match')
  expect_error(parse_cn_number('1', strict = NA), 'strict')
  latin <- iconv('\u00a51', from = 'UTF-8', to = 'latin1')
  Encoding(latin) <- 'latin1'
  expect_identical(parse_cn_number(c(latin, '\uff11\u4e07')), c(1, 10000))
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    input <- c('1', '2')
    expected <- parser(input)
    expect_identical(cn_subset(expected, 1:2), expected)
    expect_identical(cn_subset(expected, integer()), parser(character()))
  }
})
