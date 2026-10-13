test_that('original endpoint markers cannot be resurrected by shared units', {
  for (unit in c('\u4e07', '\u4ebf\u5143', '\u5343\u5143', '%')) {
    x <- c(paste0('0-5', unit), paste0('0', unit, '-5'))
    result <- suppressWarnings(parse_cn_range(x, na = c('0', '5')))
    expect_identical(cn_problems(result)$index, 1:2)
    expect_identical(cn_problems(result)$value, x)
    expect_identical(cn_problems(result)$reason,
      rep('one or both range endpoints are invalid', 2L))
    expect_true(all(is.na(result)))
    expect_error(parse_cn_range(x, na = c('0', '5'), strict = TRUE), 'positions 1, 2')
  }
})

test_that('normalized markers are retained on signed and grouped endpoints', {
  for (case in list(c(' -0 -5\u4e07', '-0'), c('1e-3-2e-3\u4e07', '1e-3'),
                    c('1 234-2 345\u4e07', '\uff11\uff12\uff13\uff14'),
                    c('1 234\u4e07-2 345', '2\u00a0345'),
                    c('\uff10-\uff15\u4e07', '\uff10'))) {
    result <- suppressWarnings(parse_cn_range(case[1], na = case[2]))
    expect_identical(cn_problems(result)$index, 1L)
    expect_identical(cn_problems(result)$value, case[1])
    expect_true(all(is.na(result)))
    expect_error(parse_cn_range(case[1], na = case[2], strict = TRUE), 'Failed to parse')
  }
})

test_that('marker matching stays textual and full-cell missing values take precedence', {
  valid <- parse_cn_range('0\u4e07-5\u4e07', na = '0', strict = TRUE)
  expect_identical(valid$lower, 0)
  expect_identical(valid$upper, 50000)
  expect_identical(parse_cn_range('0-5\u4e07', na = character(), strict = TRUE), valid)
  expect_error(parse_cn_range('0-5\u4e07', na = '0\u4e07', strict = TRUE), 'endpoints are invalid')
  missing <- parse_cn_range(c('0-5\u4e07', '3-5\u4e07'),
                           na = c('0', '0-5\u4e07'), strict = TRUE)
  expect_true(all(is.na(missing[1, ])))
  expect_equal(nrow(cn_problems(missing)), 0L)
  expect_identical(missing$lower[2], 30000)
})

test_that('repeated endpoint missing failures preserve original positions and factor behavior', {
  x <- rep(c('0-5\u4e07', '3-5\u4e07', '0\u4e07-5\u4e07'), 400L)
  names(x) <- seq_along(x)
  result <- suppressWarnings(parse_cn_range(x, na = '0'))
  failed <- seq.int(1L, length(x), 3L)
  expect_identical(cn_problems(result)$index, failed)
  expect_identical(cn_problems(result)$value, unname(x[failed]))
  expect_identical(result$lower, rep(c(NA_real_, 30000, 0), 400L))
  expect_identical(result$upper, rep(c(NA_real_, 50000, 50000), 400L))
  expect_identical(suppressWarnings(parse_cn_range(factor(x), na = '0')),
                   suppressWarnings(parse_cn_range(unname(x), na = '0')))
  expect_error(parse_cn_range(x, na = '0', strict = TRUE), 'positions 1, 4, 7, 10, 13')
})
