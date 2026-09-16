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
