# Run against a fresh installation, not sourced development functions:
# Rscript --vanilla docs/release-0.2.6-check.R outputs/release-0.2.6/library
.libPaths(c(commandArgs(trailingOnly = TRUE)[1L], .libPaths()))
library(cncleanr)
stopifnot(as.character(packageVersion("cncleanr")) == "0.2.6")

# Suning 2019 annual report, printed page 6, six financial rows x three years.
# Column order: 2019, 2018, 2017. Monetary rows only; do not scale EPS or ratios.
# https://www.suning.cn/static/snsite/contentresource/2020-04-20/d4ce9420-8511-4ada-ac1a-7578761392c7.PDF
cells <- c("269,228,900", "244,956,573", "187,927,764",
           "9,842,955", "13,327,559", "4,212,516",
           "-5,710,867", "-359,441", "-88,391",
           "-17,864,555", "-13,874,467", "-6,605,293",
           "236,855,045", "199,467,202", "157,276,688",
           "87,921,915", "80,917,098", "78,958,410")
expected <- c(269228900000, 244956573000, 187927764000,
              9842955000, 13327559000, 4212516000,
              -5710867000, -359441000, -88391000,
              -17864555000, -13874467000, -6605293000,
              236855045000, 199467202000, 157276688000,
              87921915000, 80917098000, 78958410000)
stopifnot(identical(parse_cn_number(cells, unit = "\u5343\u5143"), expected))
# EPS rows say yuan/share; ROE is a ratio, not a thousand-yuan amount.
stopifnot(identical(parse_cn_number(c("1.07", "1.44", "0.45")), c(1.07, 1.44, .45)))
stopifnot(isTRUE(all.equal(parse_cn_number(c("11.77%", "16.83%", "5.76%")),
                           c(.1177, .1683, .0576))))
stopifnot(nrow(cn_problems(suppressWarnings(
  parse_cn_number("11.77%", unit = "\u5343\u5143")))) == 1L)
stopifnot(identical(parse_cn_number(c("123.5", "1.5\u5343\u5143", "\u6682\u65e0"),
                                 unit = "\u5343\u5143"), c(123500, 1500, NA_real_)))

# Installed help must document the new parameter; installed examples must run.
rd <- tools::Rd_db("cncleanr")[["parse_cn_number.Rd"]]
stopifnot(grepl("unit = NULL", paste(capture.output(tools::Rd2txt(rd)), collapse = "\n"),
               fixed = TRUE))
example("parse_cn_number", package = "cncleanr", ask = FALSE)
cat("PASS: 18 real monetary cells, EPS/ratio boundaries, README example, installed help/examples\n")
