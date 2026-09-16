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
