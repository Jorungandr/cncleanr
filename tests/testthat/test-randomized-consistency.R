# Keep generated cases reproducible without changing other tests' RNG state.
cn_randomized_cases <- function(seed, code) {
  present <- exists('.Random.seed', .GlobalEnv, inherits = FALSE)
  if (present) saved <- get('.Random.seed', .GlobalEnv)
  on.exit(if (present) assign('.Random.seed', saved, .GlobalEnv) else
    if (exists('.Random.seed', .GlobalEnv, inherits = FALSE))
      rm('.Random.seed', envir = .GlobalEnv))
  set.seed(seed)
  force(code)
}

test_that('seeded scalar and quantity combinations match independent arithmetic', {
  cn_randomized_cases(20261030, {
    n <- 3000L
    coefficient <- sample.int(999999L, n, replace = TRUE)
    suffixes <- c('', '元', '百元', '千元', '万', '亿元', '万亿', '%')
    scales <- c(1, 1, 100, 1000, 1e4, 1e8, 1e12, .01)
    unit <- sample.int(length(suffixes), n, replace = TRUE)
    form <- sample.int(4L, n, replace = TRUE)
    body <- paste0(sprintf('%.2f', coefficient / 100), suffixes[unit])
    text <- ifelse(form == 1L, body, ifelse(form == 2L, paste0('+', body),
      ifelse(form == 3L, paste0('-', body), paste0('(', body, ')'))))
    expected <- coefficient / 100 * scales[unit] * ifelse(form <= 2L, 1, -1)
    wide <- sample.int(n, n %/% 3L)
    text[wide] <- chartr('-0123456789.+%()', '－０１２３４５６７８９．＋％（）', text[wide])
    text <- paste0(' ', text, ' ')
    actual <- parse_cn_number(text, strict = TRUE)
    expect_true(all(abs(actual - expected) <= 1e-14 * pmax(1, abs(expected))))

    # Unsigned coefficients avoid conflating qualifier grammar with sign rules.
    prefix <- c('', '约', '大于', '不小于', '小于', '不大于')
    qualifier <- c('exact', 'approx', 'greater_than', 'at_least', 'less_than', 'at_most')
    kind <- sample.int(length(prefix), n, replace = TRUE)
    quantity <- parse_cn_quantity(paste0(prefix[kind], body), strict = TRUE)
    expected_quantity <- coefficient / 100 * scales[unit]
    expect_true(all(abs(quantity$value - expected_quantity) <=
      1e-14 * pmax(1, abs(expected_quantity))))
    expect_identical(quantity$qualifier, qualifier[kind])
    expect_identical(cn_summary(quantity)$counts$parsed, n)
  })
})

test_that('seeded accounting intervals match ordered independent bounds', {
  cn_randomized_cases(20261031, {
    n <- 3000L
    lo <- sample.int(99999L, n, replace = TRUE)
    hi <- sample.int(99999L, n, replace = TRUE)
    suffixes <- c('元', '百元', '千元', '万', '亿元', '万亿', '%')
    scales <- c(1, 100, 1000, 1e4, 1e8, 1e12, .01)
    unit <- sample.int(length(suffixes), n, replace = TRUE)
    placement <- sample.int(3L, n, replace = TRUE)
    left <- paste0('(', lo, ifelse(placement != 2L, suffixes[unit], ''), ')')
    right <- paste0(hi, ifelse(placement != 1L, suffixes[unit], ''))
    separator <- sample(c('-', '~', '至'), n, replace = TRUE)
    parsed <- parse_cn_range(paste0(left, separator, right), strict = TRUE)
    expect_true(all(abs(parsed$lower + lo * scales[unit]) <=
      1e-14 * pmax(1, lo * scales[unit])))
    expect_true(all(abs(parsed$upper - hi * scales[unit]) <=
      1e-14 * pmax(1, hi * scales[unit])))
    expect_true(all(parsed$lower_inclusive & parsed$upper_inclusive))
    expect_identical(cn_summary(parsed)$counts$parsed, n)
  })
})

test_that('seeded mixed batches agree with the complete R number fallback', {
  cn_randomized_cases(20261101, {
    r_parser <- parse_cn_number
    environment(r_parser) <- list2env(list(.Call = function(symbol, x, unit)
      rep(NA_real_, length(x))), parent = environment(parse_cn_number))
    # Deduplication recursively calls parse_cn_number: keep that call R-only too.
    environment(r_parser)$parse_cn_number <- r_parser
    pool <- c('3万', '１２．５％', '(2百元)', 'RMB1,234', '-0', '1e-330万亿',
      '1e309', '1e-999', '1 2', 'bad', '3万abc', NA_character_, '暂无',
      '1亿2000万', ' 1\u202f234千元 ', '0.00000000000000001', '1.7976931348623157e308')
    # Repetitions also exercise the existing fallback deduplication threshold.
    x <- setNames(sample(pool, 4096L, replace = TRUE), paste0('row', seq_len(4096L)))
    for (unit in list(NULL, '元', '百元', '千元', '万', '亿', '万亿')) {
      actual <- suppressWarnings(parse_cn_number(x, unit = unit))
      reference <- suppressWarnings(r_parser(x, unit = unit))
      expect_identical(actual, reference)
      expect_identical(1 / as.numeric(actual), 1 / as.numeric(reference))
    }
  })
})

test_that('seeded repeated subsets retain independent problem and summary counts', {
  cn_randomized_cases(20261102, {
    n <- 2048L
    kind <- sample.int(4L, n, replace = TRUE)
    input <- c('3万', 'bad', NA_character_, '暂无')[kind]
    rows <- sample.int(n, 3072L, replace = TRUE)
    for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
      result <- suppressWarnings(parser(input))
      expect_identical(cn_problems(result)$index, which(kind == 2L))
      selected <- cn_subset(result, rows)
      problems <- cn_problems(selected)
      expect_identical(problems$index, which(kind[rows] == 2L))
      expect_identical(problems$value, rep('bad', sum(kind[rows] == 2L)))
      counts <- cn_summary(selected)$counts
      expect_equal(unname(unlist(counts)), c(length(rows), sum(kind[rows] == 1L),
        sum(kind[rows] %in% c(3L, 4L)), sum(kind[rows] == 2L)))
      again <- cn_subset(selected, rev(seq_along(rows)))
      expect_identical(cn_problems(again)$index, which(rev(kind[rows]) == 2L))
      expect_identical(cn_summary(again), cn_summary(selected))
      expect_identical(cn_summary(cn_subset(result, integer()))$counts$total, 0L)
    }
  })
})
