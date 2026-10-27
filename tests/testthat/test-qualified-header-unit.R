test_that('quantity header units use the number parser contract', {
  q <- parse_cn_quantity(c('约3', '大于4百元', '5', '暂无'), unit='百元', strict=TRUE)
  expect_identical(q$value, c(300,400,500,NA_real_))
  expect_identical(q$qualifier, c('approx','greater_than','exact',NA_character_))
  expect_identical(parse_cn_quantity(factor(c('3','3百元')), unit='百元')$value,c(300,300))
  expect_identical(parse_cn_quantity(c(1,NA_real_,NaN),unit='千元')$value,c(1000,NA_real_,NA_real_))
  for (unit in c('元','百元','千元','万','万元','亿','亿元','万亿','万亿元')) {
    expect_identical(parse_cn_quantity('2',unit=unit)$value,parse_cn_number('2',unit=unit))
    expect_identical(parse_cn_quantity(character(),unit=unit),
                     data.frame(value=numeric(),qualifier=character()))
  }
})

test_that('range headers propagate through all endpoint paths exactly once', {
  r <- parse_cn_range(c('3-5','3-5千元','3千元-5','大于3','不大于5千元','4'),
                      unit='千元',strict=TRUE)
  expect_identical(r$lower,c(3000,3000,3000,3000,-Inf,4000))
  expect_identical(r$upper,c(5000,5000,5000,Inf,5000,4000))
  expect_identical(r$lower_inclusive,c(TRUE,TRUE,TRUE,FALSE,FALSE,TRUE))
  expect_identical(r$upper_inclusive,c(TRUE,TRUE,TRUE,FALSE,TRUE,TRUE))
  expect_identical(parse_cn_range('1 234-2 345',unit='百元',strict=TRUE)$lower,123400)
  expect_identical(parse_cn_range('-5--3',unit='百元',strict=TRUE)$upper,-300)
  expect_identical(parse_cn_range('1e-3-2e-3',unit='千元',strict=TRUE)$upper,2)
  expect_identical(parse_cn_range(factor('3-5'),unit='百元')$upper,500)
  for (unit in c('元','百元','千元','万','万元','亿','亿元','万亿','万亿元')) {
    expect_identical(parse_cn_range('2-3',unit=unit)$upper,parse_cn_number('3',unit=unit))
    expect_identical(parse_cn_range(numeric(),unit=unit)$lower,numeric())
  }
})

test_that('header failures retain source rows and strict errors', {
  for (parser in list(parse_cn_quantity,parse_cn_range)) {
    x <- c('3','4千元','5%','1亿2万','bad','4千元','暂无')
    result <- suppressWarnings(parser(x,unit='百元'))
    expect_identical(cn_problems(result)$index,c(2L,3L,4L,5L,6L))
    expect_identical(cn_problems(result)$value,x[c(2,3,4,5,6)])
    expect_error(parser(x,unit='百元',strict=TRUE),'positions 2, 3, 4, 5, 6')
    numeric <- suppressWarnings(parser(c(1,Inf,1e308,NA_real_),unit='百元'))
    expect_identical(cn_problems(numeric)$index,2:3)
    expect_error(parser(c(1,Inf),unit='百元',strict=TRUE),'positions 2')
    expect_error(parser(character(),unit='百'),'`unit`')
    expect_error(parser(numeric(),unit=c('元','万元')),'`unit`')
    expect_error(parser('2',unit=NA_character_),'`unit`')
    expect_error(parser('2',unit=100),'`unit`')
    expect_equal(nrow(cn_problems(parser('保密',na='保密',unit='百元'))),0L)
  }
  for (input in c('5-3','3%-5%','3元-5','1 23-2 345','NA-5'))
    expect_error(parse_cn_range(input,unit='百元',strict=TRUE))
})

test_that('default numeric semantics and trailing argument compatibility remain intact', {
  x <- c(1,Inf,-Inf,NaN,NA_real_)
  expect_identical(parse_cn_quantity(x)$value,x)
  expect_identical(parse_cn_range(x)$lower,x)
  expect_identical(parse_cn_quantity('3',character(),TRUE,'百元')$value,300)
  expect_identical(parse_cn_range('3-5',character(),TRUE,'百元')$upper,500)
})

test_that('header results retain diagnostics across subset and summary workflows', {
  for (parser in list(parse_cn_quantity,parse_cn_range)) {
    x <- suppressWarnings(parser(c('3','bad','5%'),unit='百元'))
    selected <- cn_subset(x,c(3,1,2,3))
    expect_identical(cn_problems(selected)$index,c(1L,3L,4L))
    expect_identical(cn_summary(selected)$counts,
      data.frame(total=4L,parsed=1L,missing=0L,failed=3L))
    expect_error(parser('1e-330',unit='百元',strict=TRUE))
    expect_identical(parser('1e-325',unit='百元',strict=TRUE)[[1L]],1e-323)
    expect_identical(parser('3亿元',unit='亿',strict=TRUE)[[1L]],3e8)
  }
  expect_error(parse_cn_range('约3',unit='百元',strict=TRUE),'approximate')
  expect_identical(parse_cn_range('3百元-5千元',unit=NULL,strict=TRUE)$upper,5000)
})
