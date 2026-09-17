test_that("README enterprise workflow keeps results and problems aligned", {
  enterprises <- data.frame(
    company = paste0(c("甲", "乙", "丙", "丁", "戊"), "公司"),
    revenue_raw = c("3.2亿元", "约5万", "10万+", "暂无", "3万abc")
  )

  parsed <- suppressWarnings(parse_cn_quantity(enterprises$revenue_raw))
  cleaned <- cbind(enterprises, parsed)
  problems <- cn_problems(parsed)
  problem_rows <- cbind(
    company = enterprises$company[problems$index],
    problems
  )

  expect_equal(cleaned$value, c(3.2e8, 5e4, 1e5, NA, NA))
  expect_equal(
    cleaned$qualifier,
    c("exact", "approx", "at_least", NA, NA)
  )
  expect_equal(problems$index, 5L)
  expect_equal(problem_rows$company, "戊公司")
})
