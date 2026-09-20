test_that("closed ranges and shared suffixes are parsed", {
  result <- parse_cn_range(c("3万-5万", "3-5万", "10%-20%", "2亿至3亿"))

  expect_equal(result$lower, c(3e4, 3e4, 0.1, 2e8))
  expect_equal(result$upper, c(5e4, 5e4, 0.2, 3e8))
  expect_true(all(result$lower_inclusive))
  expect_true(all(result$upper_inclusive))
})

test_that("exponent signs and negative signs are not mistaken for separators", {
  result <- parse_cn_range(c("1e-3", "1e-3-2e-3", "-5--3"))

  expect_equal(result$lower, c(1e-3, 1e-3, -5))
  expect_equal(result$upper, c(1e-3, 2e-3, -3))
  expect_true(all(result$lower_inclusive))
  expect_true(all(result$upper_inclusive))
})

test_that("requested inequality forms map to correct open and closed bounds", {
  result <- parse_cn_range(c(
    "大于3万", "小于3万", "不大于3万", "不小于3万", "10万+", "50余"
  ))

  expect_equal(result$lower, c(3e4, -Inf, -Inf, 3e4, 1e5, 50))
  expect_equal(result$upper, c(Inf, 3e4, 3e4, Inf, Inf, Inf))
  expect_equal(result$lower_inclusive, c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE))
  expect_equal(result$upper_inclusive, c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE))
})

test_that("yu forms create consistent open lower bounds", {
  result <- parse_cn_range(c(
    "50余", "10万余", "50余万", "50余元", "50余万元"
  ))

  expect_equal(result$lower, c(50, 1e5, 5e5, 50, 5e5))
  expect_equal(result$upper, rep(Inf, 5L))
  expect_false(any(result$lower_inclusive))
  expect_false(any(result$upper_inclusive))
})

test_that("open bounds and exact values are represented explicitly", {
  result <- parse_cn_range(
    c("10万元以上", "超过2亿", "低于5000", "3万", NA)
  )

  expect_equal(result$lower[1:4], c(1e5, 2e8, -Inf, 3e4))
  expect_equal(result$upper[1:4], c(Inf, Inf, 5000, 3e4))
  expect_equal(result$lower_inclusive[1:4], c(TRUE, FALSE, FALSE, TRUE))
  expect_equal(result$upper_inclusive[1:4], c(FALSE, FALSE, FALSE, TRUE))
  expect_true(all(is.na(result[5L, ])))
})

test_that("invalid and reversed ranges report problems", {
  result <- NULL
  expect_warning(
    result <- parse_cn_range(c("5万-3万", "3万-abc", "2万")),
    "Failed to parse 2 values"
  )
  expect_equal(cn_problems(result)$index, 1:2)
  expect_equal(result$lower[[3L]], 2e4)
  expect_error(
    parse_cn_range("5万-3万", strict = TRUE),
    "range lower bound is greater than its upper bound"
  )
})

test_that("numeric inputs become inclusive point ranges", {
  numeric_input <- c(
    finite = 3,
    positive = Inf,
    negative = -Inf,
    missing = NA,
    nan = NaN
  )
  result <- parse_cn_range(numeric_input)

  expect_identical(result$lower, c(3, Inf, -Inf, NA_real_, NaN))
  expect_identical(result$upper, c(3, Inf, -Inf, NA_real_, NaN))
  expect_identical(result$lower_inclusive, c(TRUE, TRUE, TRUE, NA, NA))
  expect_identical(result$upper_inclusive, c(TRUE, TRUE, TRUE, NA, NA))
})

test_that("missing and malformed range endpoints are structured problems", {
  result <- NULL

  expect_warning(
    result <- parse_cn_range(c("3-NA", "NA-3", "1 2", "1 234")),
    "Failed to parse 3 values"
  )
  expect_equal(cn_problems(result)$index, 1:3)
  expect_equal(
    cn_problems(result)$reason,
    c(
      "one or both range endpoints are invalid",
      "one or both range endpoints are invalid",
      "digits use invalid whitespace grouping"
    )
  )
  expect_true(all(is.na(result[1:3, ])))
  expect_equal(result$lower[[4L]], 1234)
  expect_equal(result$upper[[4L]], 1234)
})

test_that("range parser expands duplicate, factor, empty, and custom missing input", {
  duplicated <- parse_cn_range(rep(c("3万-5万", "不少于2万"), each = 3L))
  factor_result <- parse_cn_range(factor(c("1万", "2万-3万")))

  expect_equal(duplicated$lower, c(rep(3e4, 3L), rep(2e4, 3L)))
  expect_equal(duplicated$upper, c(rep(5e4, 3L), rep(Inf, 3L)))
  expect_equal(factor_result$lower, c(1e4, 2e4))
  expect_equal(factor_result$upper, c(1e4, 3e4))
  expect_equal(nrow(parse_cn_range(character())), 0L)
  expect_true(all(is.na(parse_cn_range("保密", na = "保密"))))
})

test_that("range parser expands duplicated problems to original positions", {
  result <- NULL

  expect_warning(
    result <- parse_cn_range(c("未知", "3万-5万", "未知")),
    "Failed to parse 2 values"
  )
  expect_equal(cn_problems(result)$index, c(1L, 3L))
  expect_true(all(
    cn_problems(result)$reason == "value is not a supported range or bound"
  ))
})
