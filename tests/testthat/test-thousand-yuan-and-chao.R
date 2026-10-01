test_that("thousand yuan scales financial values safely", {
  expect_equal(parse_cn_number(c("9842955千元", "-4274696千元",
                                "人民币1.5千元", "(2千元)")),
               c(9842955000, -4274696000, 1500, -2000))
  for (input in c("1千", "1千万元", "1千元%", "1 2千元", "1e308千元")) {
    expect_error(parse_cn_number(input, strict = TRUE))
  }
})

test_that("chao and thousand-yuan qualifiers retain semantics", {
  result <- parse_cn_quantity(c("超41亿", "超 4 亿", "超过3千元",
                                "超出3千元", "不超过3千元", "50余千元"))
  expect_equal(result$value, c(4.1e9, 4e8, 3000, 3000, 3000, 50000))
  expect_equal(result$qualifier,
               c(rep("greater_than", 4), "at_most", "greater_than"))
  for (input in c("超", "超NA", "约", "约NA", "超额3千元",
                  "超3千元以上", "约超3千元")) {
    expect_error(parse_cn_quantity(input, strict = TRUE))
  }
})

test_that("ranges share thousand-yuan suffixes and keep open bounds", {
  result <- parse_cn_range(c("3-5千元", "3千元-5", "-5--3千元",
                             "超3千元", "不超过3千元"))
  expect_equal(result$lower, c(3000, 3000, -5000, 3000, -Inf))
  expect_equal(result$upper, c(5000, 5000, -3000, Inf, 3000))
  expect_equal(result$lower_inclusive, c(TRUE, TRUE, TRUE, FALSE, FALSE))
  expect_equal(result$upper_inclusive, c(TRUE, TRUE, TRUE, FALSE, TRUE))
  expect_error(parse_cn_range("5-3千元", strict = TRUE))
  expect_error(parse_cn_range("超3千元以上", strict = TRUE))
})
