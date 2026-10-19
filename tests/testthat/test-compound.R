test_that('explicit compound magnitudes have independent literal values', {
  input <- c('1亿2000万','1万亿2亿3万','1.5亿2.5万','1亿2,000万',
    '１亿２０００万','1 亿 2000 万','￥1亿2000万元','人民币1亿2000万',
    'CNY1亿2000万','1亿2000万人民币','-1亿2000万','￥-1亿2000万',
    '(1亿2000万)','0亿0万','1亿20000万')
  gold <- c(120000000,1000200030000,150025000,120000000,120000000,
    120000000,120000000,120000000,120000000,120000000,-120000000,
    -120000000,-120000000,0,300000000)
  expect_identical(parse_cn_number(input,strict=TRUE),gold)
  expect_identical(parse_cn_quantity(input,strict=TRUE)$value,gold)
  points <- parse_cn_range(input,strict=TRUE)
  expect_identical(points$lower,gold)
  expect_identical(points$upper,gold)
  expect_true(all(points$lower_inclusive & points$upper_inclusive))
  expect_identical(1/parse_cn_number('-0亿0万'),-Inf)
})

test_that('compound qualifiers and explicit range endpoints retain semantics', {
  input <- c('约1亿2000万','大于1亿2000万','不小于1亿2000万',
             '1亿2000万+','1亿2000万以下','约1亿2000万左右','1亿2000余万')
  result <- parse_cn_quantity(input,strict=TRUE)
  expect_identical(result$value,rep(120000000,7L))
  expect_identical(result$qualifier,c('approx','greater_than','at_least',
    'at_least','at_most','approx','greater_than'))
  range <- parse_cn_range(c('1亿2000万-2亿','1亿2000万至2亿3000万',
    '大于1亿2000万','小于1亿2000万','(2亿)-(1亿2000万)'),strict=TRUE)
  expect_identical(range$lower,c(120000000,120000000,120000000,-Inf,-200000000))
  expect_identical(range$upper,c(200000000,230000000,Inf,120000000,-120000000))
  expect_identical(range$lower_inclusive,c(TRUE,TRUE,FALSE,FALSE,TRUE))
  expect_identical(range$upper_inclusive,c(TRUE,TRUE,FALSE,FALSE,TRUE))
  expect_error(parse_cn_range('约1亿2000万',strict=TRUE),'approximate')
})

test_that('malformed and ambiguous compound expressions are never guessed', {
  bad <- c('3万5','3万5000','1万2亿','1亿2亿','1亿2万3亿',
    '1亿元2000万元','1亿2000万%','1e2亿2万','1亿-2万',
    '-￥-1亿2万','(-1亿2万)','1亿2,00万','1亿2 000万','1亿2万abc')
  for (parser in list(parse_cn_number,parse_cn_quantity)) {
    result <- suppressWarnings(parser(bad))
    value <- if (is.data.frame(result)) result$value else as.numeric(result)
    expect_true(all(is.na(value)))
    expect_identical(cn_problems(result)$index,seq_along(bad))
    expect_identical(cn_problems(result)$value,bad)
    expect_error(parser(bad,strict=TRUE),'positions 1, 2, 3, 4, 5')
  }
  for (text in c('1-2亿3000万','1亿2000万-2','1亿2000万-2%',
                 '2亿3000万-1亿2000万'))
    expect_error(parse_cn_range(text,strict=TRUE))
  for (unit in c('元','千元','万','万元','亿','亿元','万亿','万亿元'))
    expect_error(parse_cn_number('1亿2000万',unit=unit,strict=TRUE),'table-header')
})

test_that('compound failures retain positions, custom missingness and overflow checks', {
  x <- c(a='1亿2000万',b='1万2亿',c='bad',d='1亿2000万',e=NA)
  parsed <- suppressWarnings(parse_cn_number(x))
  expect_identical(names(parsed),names(x))
  expect_identical(cn_problems(parsed)$index,2:3)
  expect_identical(cn_problems(parsed)$value,unname(x[2:3]))
  expect_identical(parse_cn_number(c('1亿2000万','1亿2万'),na='1亿2000万'),c(NA_real_,100020000))
  expect_identical(parse_cn_number('1亿2万',na='1亿'),100020000)
  expect_identical(parse_cn_number(factor('1亿2000万')),120000000)
  repeated <- rep(c('1亿2000万','1万2亿','暂无'),400)
  result <- suppressWarnings(parse_cn_number(repeated))
  expect_identical(as.numeric(result),rep(c(120000000,NA_real_,NA_real_),400))
  expect_identical(cn_problems(result)$index,seq.int(2L,1200L,3L))
  for (text in c(paste0(strrep('9',310),'亿2万'),
    paste0('1',strrep('0',300),'亿1',strrep('0',304),'万')))
    expect_error(parse_cn_number(text,strict=TRUE),'finite double range')
})

test_that('generated integer compounds match arithmetic gold rather than another parser', {
  grid <- expand.grid(a=0:9,b=c(0L,2L,9999L),c=c(0L,3L))
  x <- paste0(grid$a,'万亿',grid$b,'亿',grid$c,'万')
  expected <- grid$a*1e12+grid$b*1e8+grid$c*1e4
  expect_identical(parse_cn_number(x,strict=TRUE),expected)
  expect_identical(parse_cn_quantity(x,strict=TRUE)$value,expected)
  expect_identical(parse_cn_range(x,strict=TRUE)$lower,expected)
})
