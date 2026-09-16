library(cncleanr)

stopifnot(
  identical(
    parse_cn_number(c("1.25\u4e07", "3\u4ebf\u5143", "1.2\u4e07\u4ebf")),
    c(12500, 3e8, 1.2e12)
  ),
  identical(
    parse_cn_number(c("12.5%", "\uff11\uff12\uff0e\uff15\uff05")),
    c(0.125, 0.125)
  ),
  identical(
    parse_cn_number(c("-3.2\u4ebf", "(2.5\u4e07)", "+12")),
    c(-3.2e8, -25000, 12)
  ),
  identical(
    parse_cn_number(c("\uffe53.5\u4e07", "\u4eba\u6c11\u5e012\u4ebf", "1.2e5")),
    c(35000, 2e8, 120000)
  ),
  all(is.na(parse_cn_number(c(NA, "\u6682\u65e0", "\u2014"))))
)

invalid <- suppressWarnings(
  parse_cn_number(c("3\u4e07-5\u4e07", "\u7ea63\u4e07", "2\u4e07"))
)
stopifnot(
  identical(as.numeric(invalid), c(NA_real_, NA_real_, 2e4)),
  identical(attr(invalid, "problems")$index, 1:2)
)

strict_failed <- tryCatch(
  {
    parse_cn_number("\u7ea63\u4e07", strict = TRUE)
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(strict_failed)

quantity <- parse_cn_quantity(c("\u7ea63\u4e07", "\u4e0d\u5c11\u4e8e5\u4e07"))
stopifnot(
  identical(quantity$value, c(3e4, 5e4)),
  identical(quantity$qualifier, c("approx", "at_least"))
)

range <- parse_cn_range(c("3-5\u4e07", "10\u4e07\u5143\u4ee5\u4e0a"))
stopifnot(
  identical(range$lower, c(3e4, 1e5)),
  identical(range$upper, c(5e4, Inf))
)

inequality <- parse_cn_quantity(c(
  "\u5927\u4e8e3\u4e07", "\u5c0f\u4e8e3\u4e07", "\u4e0d\u5927\u4e8e3\u4e07", "\u4e0d\u5c0f\u4e8e3\u4e07", "10\u4e07+", "50\u4f59"
))
stopifnot(
  identical(
    inequality$qualifier,
    c("greater_than", "less_than", "at_most", "at_least", "at_least", "greater_than")
  )
)

scientific_range <- parse_cn_range(c("1e-3", "1e-3-2e-3", "-5--3"))
stopifnot(
  identical(scientific_range$lower, c(1e-3, 1e-3, -5)),
  identical(scientific_range$upper, c(1e-3, 2e-3, -3))
)

normalized <- parse_cn_number(c(
  "\u22123\u4e07", "\ufe633\u4e07", "\u20133\u4e07", "\uff11\uff0e\uff12\uff25\uff15", "1\u00a0234"
))
stopifnot(identical(normalized, c(-3e4, -3e4, -3e4, 1.2e5, 1234)))

bad_spacing <- suppressWarnings(parse_cn_number(c("1 2", "1 234")))
stopifnot(
  is.na(bad_spacing[[1L]]),
  identical(bad_spacing[[2L]], 1234),
  identical(cn_problems(bad_spacing)$reason, "digits use invalid whitespace grouping")
)

yu <- parse_cn_quantity(c("50\u4f59", "10\u4e07\u4f59", "50\u4f59\u4e07", "50\u4f59\u4e07\u5143"))
stopifnot(
  identical(yu$value, c(50, 1e5, 5e5, 5e5)),
  identical(yu$qualifier, rep("greater_than", 4L))
)
