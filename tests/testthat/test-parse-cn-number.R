test_that("Chinese magnitude suffixes and currency suffixes are parsed", {
  input <- c("1.25万", "3亿元", "1.2万亿", "1,234.5万", "42人民币", "7元")

  expect_equal(
    parse_cn_number(input),
    c(12500, 3e8, 1.2e12, 12345000, 42, 7)
  )
})

test_that("currency prefixes, colloquial suffixes, and exponents are parsed", {
  input <- c(
    "￥3.5万", "人民币2亿", "RMB 12", "cny1,200", "3万块", "1.2e5",
    "-￥3万", "￥-3万", "(￥3万)"
  )

  expect_equal(
    parse_cn_number(input),
    c(35000, 2e8, 12, 1200, 30000, 120000, -30000, -30000, -30000)
  )
  expect_warning(parse_cn_number("￥3%"), "Failed to parse 1 value")
  expect_warning(parse_cn_number("1e308万"), "Failed to parse 1 value")
  expect_error(
    parse_cn_number("1e308万", strict = TRUE),
    "value is outside the finite double range"
  )
})

test_that("percentages and full-width characters are normalized", {
  input <- c("12.5%", "１２．５％", "３，０００万", " 1 234.5 万元 ")

  expect_equal(
    parse_cn_number(input),
    c(0.125, 0.125, 3e7, 12345000)
  )
})

test_that("PDF signs and full-width exponent letters are normalized", {
  input <- c("−3万", "﹣3万", "–3万", "１．２Ｅ５", "１．２ｅ５")

  expect_equal(parse_cn_number(input), c(-3e4, -3e4, -3e4, 1.2e5, 1.2e5))
})

test_that("valid Unicode whitespace grouping is accepted", {
  input <- c(
    "1 234", "1\u00a0234", "1\u202f234", "1\u3000234",
    "12 345 678.5万元"
  )

  expect_equal(
    parse_cn_number(input),
    c(1234, 1234, 1234, 1234, 12345678.5 * 1e4)
  )
})

test_that("malformed whitespace grouping is rejected instead of concatenated", {
  input <- c("1 2", "12 34", "1 23 456", "1 234")
  result <- NULL

  expect_warning(
    result <- parse_cn_number(input),
    "digits use invalid whitespace grouping"
  )
  expect_equal(as.numeric(result), c(NA_real_, NA_real_, NA_real_, 1234))
  expect_equal(cn_problems(result)$index, 1:3)
  expect_true(all(
    cn_problems(result)$reason == "digits use invalid whitespace grouping"
  ))
})

test_that("ordinary and accounting negatives are parsed", {
  expect_equal(
    parse_cn_number(c("-3.2亿", "(2.5万)", "+12")),
    c(-3.2e8, -25000, 12)
  )
})

test_that("default and custom missing markers are respected", {
  input <- c(NA, "", "NA", "N/A", "暂无", "未公布", "—", "–", "-", "...", "…")

  expect_equal(parse_cn_number(input), rep(NA_real_, length(input)))
  expect_equal(parse_cn_number(c("保密", "2"), na = "保密"), c(NA_real_, 2))
})

test_that("numeric and factor inputs work and names are preserved", {
  numeric_input <- c(a = 1, b = NA_real_, c = -2.5)
  factor_input <- factor(c("1万", "2亿"))

  expect_equal(parse_cn_number(numeric_input), numeric_input)
  expect_equal(parse_cn_number(factor_input), c(1e4, 2e8))
  expect_equal(parse_cn_number(character()), numeric())
})

test_that("invalid and ambiguous values are visible in non-strict mode", {
  input <- c("3万-5万", "约3万", "abc", "3万%", "2万")

  output <- NULL
  expect_warning(
    output <- parse_cn_number(input),
    "Failed to parse 4 values"
  )
  expect_equal(as.numeric(output), c(NA_real_, NA_real_, NA_real_, NA_real_, 2e4))

  problems <- attr(output, "problems")
  expect_s3_class(problems, "data.frame")
  expect_equal(problems$index, 1:4)
  expect_equal(problems$value, input[1:4])
  expect_true(all(nzchar(problems$reason)))
})

test_that("strict mode rejects the complete invalid batch", {
  expect_error(
    parse_cn_number(c("1万", "约3万", "3万-5万"), strict = TRUE),
    "Failed to parse 2 values"
  )
})

test_that("unsupported input types and invalid arguments fail clearly", {
  expect_error(parse_cn_number(list("1万")), "character, factor, or numeric")
  expect_error(parse_cn_number("1万", strict = NA), "single TRUE or FALSE")
  expect_error(parse_cn_number("1万", na = 1), "character vector")
})

test_that("cn_problems returns a stable problem schema", {
  failed <- suppressWarnings(parse_cn_number(c("bad", "2万")))

  expect_equal(names(cn_problems(failed)), c("index", "value", "reason"))
  expect_equal(cn_problems(failed)$index, 1L)
  expect_equal(nrow(cn_problems(parse_cn_number("2万"))), 0L)
})
