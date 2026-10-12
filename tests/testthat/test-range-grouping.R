test_that('range endpoints validate grouped digits independently', {
  grid <- expand.grid(space = c(' ', '\u00a0', '\u202f', '\u3000', '\t', '\n'),
    separator = c('-', '~', '\uff5e', '\u81f3', '\u5230', '\u2014', '\u2013'),
    stringsAsFactors = FALSE)
  x <- paste0('1', grid$space, '234', grid$separator, '2', grid$space, '345')
  result <- parse_cn_range(x, strict = TRUE)
  expect_identical(result$lower, rep(1234, nrow(grid)))
  expect_identical(result$upper, rep(2345, nrow(grid)))
  expect_true(all(result$lower_inclusive & result$upper_inclusive))
  expect_equal(nrow(cn_problems(result)), 0L)

  x <- c('1 234-2345', '1234-2 345', '1 234.5-2 345.6',
    '1 234e-2-2 345e-2', '-2 345--1 234', '(2 345)-(1 234)',
    '1 234 \u4e07 \u5143 - 2 345', '1 234 - 2 345 \u4e07 \u5143',
    '1 234\u5143 - 2 345\u5143', '1 234%-2 345%',
    '\uff11 \uff12\uff13\uff14-\uff12 \uff13\uff14\uff15\u5343\u5143')
  result <- parse_cn_range(x, strict = TRUE)
  expect_equal(result$lower, c(1234, 1234, 1234.5, 12.34, -2345, -2345,
                              1234e4, 1234e4, 1234, 12.34, 1234e3))
  expect_equal(result$upper, c(2345, 2345, 2345.6, 23.45, -1234, -1234,
                              2345e4, 2345e4, 2345, 23.45, 2345e3))
})

test_that('grouped ranges retain conservative errors and original row indices', {
  x <- c('1 23-2 345', '1 234-2 34', '1 2', '2 345-1 234',
         '1 234-2 345', 'bad', '1 234-2 345-3 456', '1 234-NA',
         '1 234-2 345', '3\u4e07', '\u6682\u65e0')
  names(x) <- paste0('row', seq_along(x))
  expect_warning(result <- parse_cn_range(x), 'positions 1, 2, 3, 4, 6')
  failed <- c(1L, 2L, 3L, 4L, 6L, 7L, 8L)
  expect_identical(cn_problems(result)$index, failed)
  expect_identical(cn_problems(result)$value, unname(x[failed]))
  expect_identical(cn_problems(result)$reason[4L], 'range lower bound is greater than its upper bound')
  expect_true(all(is.na(result[failed, ])))
  expect_identical(result$lower[c(5, 9, 10)], c(1234, 1234, 30000))
  expect_identical(result$upper[c(5, 9, 10)], c(2345, 2345, 30000))
  expect_error(parse_cn_range(x, strict = TRUE), 'First problem: digits use invalid whitespace grouping')
  expect_error(parse_cn_range('2 345-1 234', strict = TRUE), 'lower bound is greater')
  expect_identical(parse_cn_range(factor(unname(x[c(5, 9, 10)]))),
                   parse_cn_range(unname(x[c(5, 9, 10)])))
  missing <- parse_cn_range(c('1 234-2 345', '3-5\u4e07'), na = '1234-2345', strict = TRUE)
  expect_true(all(is.na(missing[1, ])))
  expect_identical(missing$lower[2], 30000)
  for (parser in list(parse_cn_number, parse_cn_quantity))
    expect_error(parser('1 234-2 345', strict = TRUE), 'Failed to parse')
})

test_that('generated grouped endpoints agree with known numeric bounds', {
  lower <- as.double(seq_len(500L) * 1000L + 234L)
  upper <- lower + 1111
  grouped <- function(x) sub('([0-9]+)([0-9]{3})$', '\\1 \\2', as.character(x))
  x <- paste0(grouped(lower), '-', grouped(upper), '\u4e07')
  result <- parse_cn_range(x, strict = TRUE)
  expect_identical(result$lower, lower * 1e4)
  expect_identical(result$upper, upper * 1e4)
  expect_true(all(result$lower_inclusive & result$upper_inclusive))
  expect_equal(nrow(cn_problems(result)), 0L)
})
