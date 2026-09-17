test_that("all parsers preserve input cardinality", {
  input <- c("1万", "bad", NA, "1 2")

  expect_length(suppressWarnings(parse_cn_number(input)), length(input))
  expect_equal(nrow(suppressWarnings(parse_cn_quantity(input))), length(input))
  expect_equal(nrow(suppressWarnings(parse_cn_range(input))), length(input))
})

test_that("invalid non-missing values are NA and visible as problems", {
  input <- c("1万", "bad", "???")

  number <- suppressWarnings(parse_cn_number(input))
  quantity <- suppressWarnings(parse_cn_quantity(input))
  range <- suppressWarnings(parse_cn_range(input))

  expect_equal(cn_problems(number)$index, c(2L, 3L))
  expect_true(all(is.na(number[cn_problems(number)$index])))

  expect_equal(cn_problems(quantity)$index, c(2L, 3L))
  expect_true(all(is.na(quantity$value[cn_problems(quantity)$index])))
  expect_true(all(is.na(quantity$qualifier[cn_problems(quantity)$index])))

  expect_equal(cn_problems(range)$index, c(2L, 3L))
  expect_true(all(is.na(range[cn_problems(range)$index, ])))
})

test_that("strict and non-strict modes identify the same positions", {
  input <- c("1万", "bad", "2亿", "???")
  non_strict <- suppressWarnings(parse_cn_number(input))
  positions <- paste(cn_problems(non_strict)$index, collapse = ", ")

  expect_error(
    parse_cn_number(input, strict = TRUE),
    paste0("positions ", positions),
    fixed = TRUE
  )
})

test_that("successful exact outputs are finite and never truncated", {
  valid <- parse_cn_number(c("1万", "1.2e5", "￥3亿元", "12.5%"))
  invalid <- suppressWarnings(parse_cn_number(c("3万abc", "1e308万")))

  expect_true(all(is.finite(valid)))
  expect_true(all(is.na(invalid)))
  expect_equal(cn_problems(invalid)$index, 1:2)
})
