test_that('ranges retain specific scalar quantity failures', {
  x <- c('3%','3千元','1e307','1e-330','-3千元','大于3%')
  gold <- cn_problems(suppressWarnings(parse_cn_quantity(x,unit='百元')))
  result <- suppressWarnings(parse_cn_range(x,unit='百元'))
  expect_identical(cn_problems(result),gold)
  expect_true(all(is.na(result)))
  expect_error(parse_cn_range('3%',unit='百元',strict=TRUE),'table-header')
  expect_error(parse_cn_range('1e-330',strict=TRUE),'underflows')
  expect_error(parse_cn_range('约3以上',strict=TRUE),'multiple or conflicting qualifiers')
  expect_identical(cn_problems(suppressWarnings(parse_cn_range('bad')))$reason,
                   'value is not a supported range or bound')
})

test_that('unique range candidates retain left and right endpoint reasons', {
  conflict <- 'explicit unit conflicts with the table-header unit'
  x <- c('3千元-5百元','3百元-5千元','3千元-5千元')
  expected <- c(paste0('left range endpoint: ',conflict),
                paste0('right range endpoint: ',conflict),
                paste0('left range endpoint: ',conflict,'; right range endpoint: ',conflict))
  result <- suppressWarnings(parse_cn_range(x,unit='百元'))
  expect_identical(cn_problems(result)$reason,expected)
  expect_identical(cn_problems(result)$value,x)
  expect_error(parse_cn_range(x[2],unit='百元',strict=TRUE),'right range endpoint: explicit unit')
  overflow <- 'value is outside the finite double range'
  expect_identical(cn_problems(suppressWarnings(parse_cn_range(c('1e309~3','3~1e309'))))$reason,
    c(paste0('left range endpoint: ',overflow),paste0('right range endpoint: ',overflow)))
  expect_match(cn_problems(suppressWarnings(parse_cn_range('3万-abc')))$reason,
               '^right range endpoint: value does not match')
  expect_match(cn_problems(suppressWarnings(parse_cn_range('abc-3万')))$reason,
               '^left range endpoint: value does not match')
  expect_match(cn_problems(suppressWarnings(parse_cn_range('abc-def')))$reason,
               '^left range endpoint: .*; right range endpoint: ')
})

test_that('grouped retry and repeated failures preserve original source positions', {
  x <- c('1 234千元-2 345百元','3-5百元','3%','1 234千元-2 345百元','暂无')
  result <- suppressWarnings(parse_cn_range(factor(x),unit='百元'))
  p <- cn_problems(result)
  expect_identical(p$index,c(1L,3L,4L))
  expect_identical(p$value,x[c(1,3,4)])
  expect_match(p$reason[1],'^left range endpoint: explicit unit')
  expect_identical(result$lower,c(NA_real_,300,NA_real_,NA_real_,NA_real_))
  selected <- cn_subset(result,c(4,2,1))
  expect_identical(cn_problems(selected)$index,c(1L,3L))
  expect_identical(cn_summary(selected)$reasons$count,2L)
})

test_that('structural and missing diagnostics do not guess endpoint causes', {
  missing <- suppressWarnings(parse_cn_range(c('3-NA','NA-3','1亿2万-3')))
  expect_identical(cn_problems(missing)$reason,rep('one or both range endpoints are invalid',3))
  expect_identical(cn_problems(suppressWarnings(parse_cn_range('abc-def-ghi')))$reason,
                   'one or both range endpoints are invalid')
  expect_identical(cn_problems(suppressWarnings(parse_cn_range('1 23-2 345')))$reason,
                   'digits use invalid whitespace grouping')
  expect_error(parse_cn_range('3%-5元',strict=TRUE),'incompatible units')
  expect_error(parse_cn_range('5-3',strict=TRUE),'lower bound is greater')
  expect_error(parse_cn_range('约3',strict=TRUE),'approximate')
  expect_error(parse_cn_range(paste(rep('1',20),collapse='-'),strict=TRUE),'too many separators')
})

test_that('detailed failures reuse existing parser calls rather than reparsing rows', {
  ns <- asNamespace('cncleanr')
  sandbox <- new.env(parent=ns)
  for (name in c('parse_cn_range','parse_cn_quantity','find_cn_range_endpoints_batch')) {
    method <- get(name,ns)
    environment(method) <- sandbox
    sandbox[[name]] <- method
  }
  number_calls <- quantity_calls <- 0L
  quantity <- sandbox$parse_cn_quantity
  sandbox$parse_cn_number <- function(...) {
    number_calls <<- number_calls+1L
    get('parse_cn_number',ns)(...)
  }
  sandbox$parse_cn_quantity <- function(...) {
    quantity_calls <<- quantity_calls+1L
    quantity(...)
  }
  suppressWarnings(sandbox$parse_cn_range(c('3-5','3千元-5百元','3%'),unit='百元'))
  expect_identical(quantity_calls,1L)
  expect_identical(number_calls,2L)
})
