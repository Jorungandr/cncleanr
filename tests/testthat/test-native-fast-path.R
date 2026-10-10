test_that('native accepted cells agree with the complete R fallback', {
  r_parser <- parse_cn_number
  environment(r_parser) <- list2env(list(.Call = function(symbol, x, unit) rep(NA_real_, length(x))),
    parent = environment(parse_cn_number))
  grid <- expand.grid(
    prefix = c('', '-', '+', '(', 'RMB', '-RMB+'),
    body = c('0', '.25', '.', '1.', '1e-999', '1e309', '1e308',
             '1,234', '1 2', '１２', '0x12', 'bad'),
    suffix = c('', '万', '亿元', '千元', '万亿', '%', '万%', ')', '元元'),
    stringsAsFactors = FALSE)
  x <- c(do.call(paste0, grid), NA_character_)
  # Disable native calls in the reference so acceleration cannot hide a false match.
  for (header in c(NA_real_, 1, 1e3, 1e4, 1e8, 1e12)) {
    unit <- if (is.na(header)) NULL else
      c('元', '千元', '万', '亿', '万亿')[match(header, c(1, 1e3, 1e4, 1e8, 1e12))]
    reference <- suppressWarnings(r_parser(x, unit = unit))
    native <- .Call(cncleanr:::C_simple_numbers, x, header)
    handled <- which(!is.na(native))
    expect_identical(native[handled], as.numeric(reference)[handled])
    expect_false(any(handled %in% cn_problems(reference)$index))
  }
})

test_that('native batches preserve names, missing markers and negative zero', {
  x <- c(a = '3万', b = '-0%', c = NA_character_, d = '2e-3')
  expect_identical(parse_cn_number(x), c(a = 30000, b = -0, c = NA_real_, d = .002))
  expect_identical(1 / parse_cn_number('-0'), -Inf)
  expect_identical(parse_cn_number(c('3万', '2'), na = '３万'), c(NA_real_, 2))
  expect_identical(parse_cn_number(c('3', '3万'), unit = '万'), c(30000, 30000))
  expect_error(.Call(cncleanr:::C_simple_numbers, 1, NA_real_), 'Invalid native')
  expect_error(.Call(cncleanr:::C_simple_numbers, '1', numeric()), 'Invalid native')
})

test_that('native floating-point boundaries agree with the R fallback', {
  r_parser <- parse_cn_number
  environment(r_parser) <- list2env(list(.Call = function(symbol, x, unit) rep(NA_real_, length(x))),
    parent = environment(parse_cn_number))
  grid <- expand.grid(
    sign = c('', '-', '+'),
    mantissa = c('0', '1', '1.7976931348623157',
                 '2.2250738585072014', '4.9406564584124654'),
    exponent = paste0('e', c(-325, -324, -308, -1, 0, 1, 296, 308, 309)),
    suffix = c('', '%', '\u5143', '\u4e07', '\u4ebf', '\u4e07\u4ebf'),
    stringsAsFactors = FALSE)
  x <- do.call(paste0, grid)
  for (unit in list(NULL, '\u5143', '\u5343\u5143', '\u4e07', '\u4ebf', '\u4e07\u4ebf')) {
    reference <- suppressWarnings(r_parser(c(x, 'invalid'), unit = unit))
    header <- if (is.null(unit)) NA_real_ else
      c(1, 1e3, 1e4, 1e8, 1e12)[match(unit, c('\u5143', '\u5343\u5143', '\u4e07', '\u4ebf', '\u4e07\u4ebf'))]
    native <- .Call(cncleanr:::C_simple_numbers, x, header)
    handled <- which(!is.na(native))
    expect_gt(length(handled), 0L)
    expect_identical(native[handled], as.numeric(reference)[handled])
    expect_identical(1 / native[handled], 1 / as.numeric(reference)[handled])
    expect_false(any(handled %in% cn_problems(reference)$index))
    expect_identical(parse_cn_number(x[handled], unit = unit), native[handled])
  }
})

test_that('mixed native and fallback rows preserve original problem indices', {
  x <- setNames(c('2\u4e07', '1 2', '\uff13\u4e07', '4', '(5\u5143)',
                  'bad', NA, '\u6682 \u65e0', '-0%', ' \uff16\u4e07'), letters[1:10])
  expect_warning(result <- parse_cn_number(x), 'positions 2, 6')
  expected <- setNames(c(20000, NA, 30000, 4, -5, NA, NA, NA, -0, 60000), names(x))
  expect_identical(as.numeric(result), unname(expected))
  expect_identical(names(result), names(expected))
  expect_identical(1 / result[[9L]], -Inf)
  expect_identical(cn_problems(result)$index, c(2L, 6L))
  expect_identical(cn_problems(result)$value, unname(x[c(2L, 6L)]))
  expect_identical(cn_problems(result)$reason,
    c('digits use invalid whitespace grouping', 'value does not match the supported number syntax'))
  expect_error(parse_cn_number(x, strict = TRUE), 'positions 2, 6')
  expect_identical(parse_cn_number(c('3\u4e07', ' NA'), na = c('\uff13\u4e07', 'NA')),
    c(NA_real_, NA_real_))
})

test_that('currency and accounting acceleration preserves sign restrictions', {
  valid <- c('RMB3\u4e07', 'rMb-3\u5143', '-CNY2\u4ebf', '\u00a53',
             '\u4eba\u6c11\u5e013\u5343\u5143', '(RMB2\u4e07)', '(3%)', '(0)')
  expected <- c(30000, -3, -2e8, 3, 3000, -20000, -.03, -0)
  expect_identical(.Call(cncleanr:::C_simple_numbers, valid, NA_real_), expected)
  expect_identical(parse_cn_number(valid), expected)
  expect_identical(1 / parse_cn_number('(0)'), -Inf)
  invalid <- c('(-3)', '(+3)', '-RMB+3', '(RMB-3)', 'RMB3%',
               'RMB', 'R', 'RM', 'C', 'CN', '(', 'RMB3\u5143)')
  expect_true(all(is.na(.Call(cncleanr:::C_simple_numbers, invalid, NA_real_))))
  result <- suppressWarnings(parse_cn_number(invalid))
  expect_identical(cn_problems(result)$index, seq_along(invalid))
})

test_that('normalized acceleration still validates spacing and missing markers', {
  x <- c(' RMB 3 \u4e07 ', ' ( \uffe5\uff12\u4e07 ) ', '\uff11\uff12\uff0e\uff15\uff05',
         '1 234\u5143', '1 23\u5143', '\uff13\u4e07')
  expect_warning(result <- parse_cn_number(x, na = '3\u4e07'), 'positions 5')
  expect_identical(as.numeric(result), c(30000, -20000, .125, 1234, NA, NA))
  expect_identical(cn_problems(result)$index, 5L)
  expect_identical(cn_problems(result)$reason, 'digits use invalid whitespace grouping')
  expect_identical(parse_cn_number(' RMB 3 \u4e07 ', unit = '\u4e07'), 30000)
})
