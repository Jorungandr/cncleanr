test_that("qualified quantities preserve their semantics", {
  result <- parse_cn_quantity(
    c("3万", "约3万", "超过2亿", "不少于5万", "低于1.5亿", "10%以下")
  )

  expect_equal(result$value, c(3e4, 3e4, 2e8, 5e4, 1.5e8, 0.1))
  expect_equal(
    result$qualifier,
    c("exact", "approx", "greater_than", "at_least", "less_than", "at_most")
  )
})

test_that("common inequality phrases have precise boundary semantics", {
  result <- parse_cn_quantity(c(
    "大于3万", "小于3万", "不大于3万", "不小于3万", "10万+", "50余"
  ))

  expect_equal(result$value, c(3e4, 3e4, 3e4, 3e4, 1e5, 50))
  expect_equal(
    result$qualifier,
    c("greater_than", "less_than", "at_most", "at_least", "at_least", "greater_than")
  )
})

test_that("yu before or after a unit consistently means greater than", {
  result <- parse_cn_quantity(c(
    "50余", "10万余", "50余万", "50余元", "50余万元"
  ))

  expect_equal(result$value, c(50, 1e5, 5e5, 50, 5e5))
  expect_equal(result$qualifier, rep("greater_than", 5L))
})

test_that("ASCII, Unicode, and full-width comparison signs are supported", {
  result <- parse_cn_quantity(c(
    ">3万", "<3万", ">=3万", "<=3万", "≥3万", "≤3万", "＞３万", "＜＝３万"
  ))

  expect_equal(result$value, rep(3e4, 8L))
  expect_equal(
    result$qualifier,
    c(
      "greater_than", "less_than", "at_least", "at_most",
      "at_least", "at_most", "greater_than", "at_most"
    )
  )
})

test_that("quantity parser handles missing, numeric, and invalid input", {
  expect_equal(
    parse_cn_quantity(c(NA, "暂无"))$qualifier,
    c(NA_character_, NA_character_)
  )
  expect_equal(parse_cn_quantity(c(1, 2))$qualifier, c("exact", "exact"))

  result <- NULL
  expect_warning(
    result <- parse_cn_quantity(c("约3万以上", "2万")),
    "Failed to parse 1 value"
  )
  expect_true(is.na(result$value[[1L]]))
  expect_equal(cn_problems(result)$index, 1L)
  expect_error(parse_cn_quantity("约3万以上", strict = TRUE), "Failed to parse")
})

test_that("numeric quantities preserve special values and qualifiers", {
  numeric_input <- c(
    finite = 3,
    positive = Inf,
    negative = -Inf,
    missing = NA,
    nan = NaN
  )
  result <- parse_cn_quantity(numeric_input)

  expect_identical(result$value, c(3, Inf, -Inf, NA_real_, NaN))
  expect_identical(
    result$qualifier,
    c("exact", "exact", "exact", NA_character_, NA_character_)
  )
})
