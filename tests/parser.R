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
