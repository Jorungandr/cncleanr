test_that("header units scale only bare values", {
  expect_equal(parse_cn_number(c("123.5", "1.5千元", "(2)"), unit = "千元"),
               c(123500, 1500, -2000))
  expect_equal(parse_cn_number(c("3", "3万元", "3万"), unit = "万元"),
               rep(30000, 3))
  expect_equal(parse_cn_number(c(a = 1, b = NA_real_), unit = "千元"),
               c(a = 1000, b = NA_real_))
  precise <- 1.2345678901234567
  expect_identical(parse_cn_number(precise, unit = "千元"), precise * 1000)
  expect_equal(parse_cn_number(factor(c("2", "暂无")), unit = "亿元"),
               c(2e8, NA_real_))
  expect_equal(parse_cn_number(c("１．５", "1 234", "2e-3"), unit = "千元"),
               c(1500, 1234000, 2))
  expect_equal(parse_cn_number(c("保密", "2"), na = "保密", unit = "千元"),
               c(NA_real_, 2000))
  for (unit in c("元", "百元", "千元", "万", "万元", "亿", "亿元", "万亿", "万亿元")) {
    expect_true(is.finite(parse_cn_number("2", unit = unit)))
  }
})

test_that("header unit conflicts use existing failure reporting", {
  result <- suppressWarnings(parse_cn_number(c("2", "3万元", "5%", "暂无"),
                                             unit = "千元"))
  expect_equal(as.numeric(result), c(2000, NA_real_, NA_real_, NA_real_))
  expect_equal(cn_problems(result)$index, c(2L, 3L))
  expect_equal(cn_problems(result)$value, c("3万元", "5%"))
  for (input in c("3万元", "3元", "￥3", "5%", "1e308", "bad", "1 2")) {
    expect_error(parse_cn_number(input, unit = "千元", strict = TRUE))
  }
  expect_error(parse_cn_number(Inf, unit = "千元", strict = TRUE))
  expect_equal(parse_cn_number(c(NA_real_, NaN), unit = "千元"),
               c(NA_real_, NA_real_))
})

test_that("unit validation and existing positional calls stay safe", {
  for (unit in list("", "千", "美元", "%", NA_character_, c("元", "万元"), 1000)) {
    expect_error(parse_cn_number(character(), unit = unit), "unit")
  }
  expect_identical(parse_cn_number(character(), unit = "千元"), numeric())
  expect_equal(parse_cn_number(c("1", "missing"), "missing", TRUE), c(1, NA_real_))
  expect_identical(parse_cn_number(c(Inf, -Inf, NaN)), c(Inf, -Inf, NaN))
})

test_that('numeric conversion precedes header scaling and missing detection', (function() {
  table <- get('.__S3MethodsTable__.', envir = asNamespace('base'))
  method <- 'as.double.cncleanr_test_numeric'
  stopifnot(!exists(method, envir = table, inherits = FALSE))
  on.exit(rm(list = method, envir = table))
  calls <- 0L
  registerS3method('as.double', 'cncleanr_test_numeric', function(x, ...) {
    calls <<- calls + 1L
    value <- unclass(x)
    value[which(value == -999)] <- NA_real_
    value * 30000
  }, envir = asNamespace('base'))
  x <- structure(c(a = 1, b = -999, c = NA_real_, d = NaN, e = -0),
                 class = 'cncleanr_test_numeric')
  expected <- c(a = 30000, b = NA_real_, c = NA_real_, d = NaN, e = -0)
  expect_identical(parse_cn_number(x), expected)
  expect_identical(calls, 1L)
  calls <- 0L
  scaled <- parse_cn_number(x, unit = '万', strict = TRUE)
  expect_identical(scaled, c(a = 3e8, b = NA_real_, c = NA_real_, d = NA_real_, e = -0))
  expect_identical(calls, 1L)
  expect_identical(1 / scaled['e'], c(e = -Inf))
  expect_identical(cn_problems(scaled)$index, integer())
  expect_identical(parse_cn_quantity(x)$value, unname(expected))
  expect_identical(parse_cn_range(x)$lower, unname(expected))
  empty <- structure(setNames(numeric(), character()), class = 'cncleanr_test_numeric')
  expect_identical(parse_cn_number(empty, unit = '千元'), setNames(numeric(), character()))
  for (unit in c('元', '百元', '千元', '万', '万元', '亿', '亿元', '万亿', '万亿元')) {
    expect_identical(parse_cn_number(x, unit = unit),
                     parse_cn_number(expected, unit = unit))
  }
  infinite <- structure(c(1, Inf, -Inf, NaN, -999), class = 'cncleanr_test_numeric')
  result <- suppressWarnings(parse_cn_number(infinite, unit = '千元'))
  expect_identical(as.numeric(result), c(3e7, NA_real_, NA_real_, NA_real_, NA_real_))
  expect_identical(cn_problems(result)$index, 2:3)
  expect_identical(cn_problems(result)$value, c('Inf', '-Inf'))
  expect_error(parse_cn_number(infinite, unit = '千元', strict = TRUE), 'positions 2, 3')
  for (input in list(1:3, c(1.25, -0, NA, NaN, Inf))) {
    expect_identical(parse_cn_number(input), as.double(input))
    expect_identical(suppressWarnings(parse_cn_number(input, unit = '万')),
      suppressWarnings(parse_cn_number(as.character(input), unit = '万', na = c('NA', 'NaN'))))
  }
})())
