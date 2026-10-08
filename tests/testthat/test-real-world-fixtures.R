test_that("open-data notes do not silently become numbers or missing values", {
  text <- c("10,536", "-", "#VALUE!", "未統計",
            "27,091(外國跑者3,249人)", "活動仍辦理中")
  default <- suppressWarnings(parse_cn_number(text))
  expect_equal(as.numeric(default), c(10536, rep(NA_real_, 5)))
  expect_equal(cn_problems(default)$index, 3:6)
  custom <- suppressWarnings(parse_cn_number(text, na=c("", "-", "未統計")))
  expect_equal(as.numeric(custom), as.numeric(default))
  expect_equal(cn_problems(custom)$index, c(3L, 5L, 6L))
  for (parser in list(parse_cn_quantity, parse_cn_range)) {
    result <- suppressWarnings(parser(text))
    expect_equal(cn_problems(result)$index, 3:6)
  }
})

test_that("number fixtures match expected values and problems", {
  cases <- read_cn_fixture("number-cases.tsv")
  result <- suppressWarnings(parse_cn_number(cases$input))
  expected <- fixture_double(cases$expected)

  expect_equal(as.numeric(result), expected)
  expect_equal(cn_problems(result)$index, which(cases$status == "invalid"))
  expect_equal(
    cn_problems(result)$reason,
    cases$reason[cases$status == "invalid"]
  )
})

test_that("quantity fixtures retain semantic qualifiers", {
  cases <- read_cn_fixture("quantity-cases.tsv")
  result <- suppressWarnings(parse_cn_quantity(cases$input))
  expected_qualifier <- cases$qualifier
  expected_qualifier[expected_qualifier == ""] <- NA_character_

  expect_equal(result$value, fixture_double(cases$expected))
  expect_equal(result$qualifier, expected_qualifier)
  expect_equal(cn_problems(result)$index, which(cases$status == "invalid"))
  expect_equal(
    cn_problems(result)$reason,
    cases$reason[cases$status == "invalid"]
  )
})

test_that("range fixtures retain boundaries and inclusivity", {
  cases <- read_cn_fixture("range-cases.tsv")
  result <- suppressWarnings(parse_cn_range(cases$input))

  expect_equal(result$lower, fixture_double(cases$lower))
  expect_equal(result$upper, fixture_double(cases$upper))
  expect_equal(result$lower_inclusive, fixture_logical(cases$lower_inclusive))
  expect_equal(result$upper_inclusive, fixture_logical(cases$upper_inclusive))
  expect_equal(cn_problems(result)$index, which(cases$status == "invalid"))
  expect_equal(
    cn_problems(result)$reason,
    cases$reason[cases$status == "invalid"]
  )
})
