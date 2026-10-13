test_that('range units must have compatible dimensions', {
  x <- c('3%-5元', '3%-5万', '3元-5%', '1 234%-2 345元')
  result <- suppressWarnings(parse_cn_range(x))
  expect_true(all(is.na(result$lower)))
  expect_identical(cn_problems(result)$index, seq_along(x))
  expect_identical(cn_problems(result)$reason,
    rep('range endpoints use incompatible units', length(x)))
  expect_error(parse_cn_range(x, strict = TRUE), 'incompatible units')
  good <- parse_cn_range(c('3-5%', '3%-5', '3万-5亿'), strict = TRUE)
  expect_equal(good$lower, c(.03, .03, 30000))
  expect_equal(good$upper, c(.05, .05, 5e8))
})

test_that('number parsing preserves names before conversion and empty returns', {
  x <- factor(c('1万', 'bad', '2万'))
  names(x) <- c('a', 'b', 'c')
  result <- suppressWarnings(parse_cn_number(x))
  expect_identical(names(result), names(x))
  expect_identical(cn_problems(result)$index, 2L)
  expect_identical(names(parse_cn_number(setNames(character(), character()))), character())
  expect_identical(names(parse_cn_number(x[1], unit = '万')), 'a')
})

test_that('final decimal scale is applied before extreme conversion loses information', {
  x <- c('1e309%', '1e-330万亿', '(1e309%)', '１e－３３０万亿',
         '1,000e-333万亿', '1e-320万亿')
  result <- parse_cn_number(x, strict = TRUE)
  expect_equal(result[c(1, 3)], c(1e307, -1e307))
  expect_identical(as.numeric(result[c(2, 4, 5)]), rep(1e-318, 3))
  expect_identical(result[6], 1e-308)
  expect_identical(parse_cn_number('1e-330', unit = '万亿', strict = TRUE), 1e-318)
  expect_equal(parse_cn_quantity('约1e309%', strict = TRUE)$value, 1e307)
  expect_identical(parse_cn_range('1e-330-2e-330万亿', strict = TRUE)$lower, 1e-318)
  bad <- suppressWarnings(parse_cn_number(c('1e-999', '1e309', '1e-323%')))
  expect_true(all(is.na(bad)))
  expect_identical(cn_problems(bad)$reason,
    c('nonzero value underflows the double range',
      'value is outside the finite double range',
      'nonzero value underflows the double range'))
  expect_identical(parse_cn_number(c('0e-999', '-0e999')), c(0, -0))
})

test_that('fractional digit spacing is consistently rejected', {
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    result <- suppressWarnings(parser(c('.1 234', '0.1 234')))
    expect_identical(cn_problems(result)$index, 1:2)
    expect_identical(cn_problems(result)$reason,
      rep('digits use invalid whitespace grouping', 2))
  }
})

test_that('grouped range diagnostics describe endpoint failures', {
  missing <- suppressWarnings(parse_cn_range('1 234-2 345万', na = '1 234'))
  expect_identical(cn_problems(missing)$reason, 'one or both range endpoints are invalid')
  expect_error(parse_cn_range('1 234-2 345万', na = '1 234', strict = TRUE), 'endpoints are invalid')
  invalid <- suppressWarnings(parse_cn_range(c('1 23-2 345', '1 234-NA')))
  expect_identical(cn_problems(invalid)$reason,
    c('digits use invalid whitespace grouping', 'one or both range endpoints are invalid'))
})

test_that('malformed separator floods have a bounded candidate search', {
  x <- paste(rep('1', 1000), collapse = '-')
  result <- suppressWarnings(parse_cn_range(c(x, '-1e-3--2e-4')))
  expect_identical(cn_problems(result)$reason, 'range contains too many separators')
  expect_equal(result$lower[2], -.001)
  expect_equal(result$upper[2], -.0002)
})

test_that('boundary conversion has independent scale and zero gold values', {
  cases <- c('1e-325万', '1e-329亿', '1e-333万亿', '1e-324千元',
             '.00001e-316', '100000e-326', '1e310%', '(0e999万)',
             paste0('1', strrep('0', 10000), 'e-10000'))
  result <- parse_cn_number(cases, strict = TRUE)
  expect_identical(as.numeric(result[1:6]), rep(1e-321, 6))
  expect_identical(result[7], 1e308)
  expect_identical(1 / result[8], -Inf)
  expect_identical(result[9], 1)
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    result <- suppressWarnings(parser(rep(c('1e-999', '3万'), 600L)))
    expect_identical(cn_problems(result)$index, seq.int(1L, 1200L, 2L))
    expect_error(parser(c('1e-999', '3万'), strict = TRUE), 'Failed to parse')
  }
})
