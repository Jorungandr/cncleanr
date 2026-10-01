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
  for (unit in c("元", "千元", "万", "万元", "亿", "亿元", "万亿", "万亿元")) {
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
