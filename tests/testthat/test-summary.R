test_that('summaries separate failures from missing values across all parsers', {
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    x <- suppressWarnings(parser(c('3万', 'bad', '暂无', NA, '1 2', 'bad', '12.5%')))
    before <- x
    expect_silent(result <- cn_summary(x))
    expect_identical(names(result), c('counts','reasons'))
    expect_identical(result$counts, data.frame(total=7L,parsed=2L,missing=2L,failed=3L))
    expect_identical(result$reasons,
      data.frame(reason=c(if (identical(parser,parse_cn_range))
                            'value is not a supported range or bound' else
                            'value does not match the supported number syntax',
                          'digits use invalid whitespace grouping'),count=c(2L,1L)))
    expect_identical(x,before)
    selected <- cn_subset(x,c(6L,1L,2L,6L,3L))
    expect_identical(cn_summary(selected)$counts,
      data.frame(total=5L,parsed=1L,missing=1L,failed=3L))
    expect_identical(cn_summary(selected)$reasons$count,3L)
    expect_identical(cn_summary(cn_subset(selected,c(4L,2L,1L)))$counts,
      data.frame(total=3L,parsed=1L,missing=0L,failed=2L))
  }
})

test_that('summaries handle empty, clean, missing, nonfinite and bounded results', {
  for (parser in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    for (input in list(character(),c('暂无',NA,'-'),c('1','2'),c('bad','wrong'))) {
      result <- cn_summary(suppressWarnings(parser(input)))
      expect_identical(result$counts$total,
        result$counts$parsed+result$counts$missing+result$counts$failed)
      expect_identical(sum(result$reasons$count),result$counts$failed)
    }
    empty <- cn_summary(parser(character()))
    expect_identical(empty$counts,data.frame(total=0L,parsed=0L,missing=0L,failed=0L))
    expect_identical(empty$reasons,data.frame(reason=character(),count=integer()))
    expect_identical(cn_summary(parser(c('暂无',NA,'-')))$counts,
      data.frame(total=3L,parsed=0L,missing=3L,failed=0L))
    expect_identical(cn_summary(suppressWarnings(parser(c('bad','wrong'))))$counts,
      data.frame(total=2L,parsed=0L,missing=0L,failed=2L))
    expect_identical(cn_summary(parser(c(Inf,-Inf,NaN,NA_real_,0)))$counts,
      data.frame(total=5L,parsed=3L,missing=2L,failed=0L))
  }
  expect_identical(cn_summary(parse_cn_quantity(c('约3万','10万+','小于2万')))$counts,
    data.frame(total=3L,parsed=3L,missing=0L,failed=0L))
  expect_identical(cn_summary(parse_cn_range(c('小于3万','大于3万','3-5万')))$counts,
    data.frame(total=3L,parsed=3L,missing=0L,failed=0L))
  header <- suppressWarnings(parse_cn_number(c('3','Inf','暂无'),unit='万'))
  expect_identical(cn_summary(header)$counts,
    data.frame(total=3L,parsed=1L,missing=1L,failed=1L))
})

test_that('summary validates obvious malformed results and stale diagnostics', {
  for (x in list('1',TRUE,list(1),matrix(1),1+1i,data.frame(wrong=1),
                 data.frame(value='1',qualifier='exact'),
                 data.frame(lower=1,upper='2',lower_inclusive=TRUE,upper_inclusive=TRUE)))
    expect_error(cn_summary(x),'result')
  original <- suppressWarnings(parse_cn_number(c('bad','2')))
  problems <- cn_problems(original)
  for (index in list(2L,3L,0L,NA_integer_,Inf,.5,c(1L,1L))) {
    x <- original
    p <- problems[rep(1L,length(index)),,drop=FALSE]
    p$index <- index
    attr(x,'problems') <- p
    expect_error(cn_summary(x),'problems')
  }
  for (p in list(list(),data.frame(index=1L,value='bad',reason=NA_character_),
                  data.frame(index=1L,value=1,reason='bad'),
                  data.frame(index=1L,value='bad',reason=''))) {
    x <- original
    attr(x,'problems') <- p
    expect_error(cn_summary(x),'problems')
  }
  range <- parse_cn_range(c(1,NA_real_))
  range$upper[2L] <- 1
  expect_error(cn_summary(range),'result')
})

test_that('summary does not invoke parsers or coerce original input again', {
  result <- suppressWarnings(parse_cn_number(c('3万','bad','暂无')))
  ns <- asNamespace('cncleanr')
  isolated <- new.env(parent=ns)
  for (name in c('cn_summary','cn_result_problems','cn_problems')) {
    method <- get(name,ns)
    environment(method) <- isolated
    isolated[[name]] <- method
  }
  for (name in c('parse_cn_number','parse_cn_quantity','parse_cn_range',
                 'cn_numeric_values','normalize_cn_number_text'))
    isolated[[name]] <- function(...) stop('unexpected reparsing')
  expect_identical(isolated$cn_summary(result)$counts,
    data.frame(total=3L,parsed=1L,missing=1L,failed=1L))
})
