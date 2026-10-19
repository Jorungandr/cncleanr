test_that('hundred yuan follows the existing thousand-yuan monetary rules', {
  input <- c('3百元','1.5百元','３百元','￥3百元','-3百元','(3百元)',
             '1,234百元','1 234百元','3e2百元','人民币3百元')
  gold <- c(300,150,300,300,-300,-300,123400,123400,30000,300)
  expect_identical(parse_cn_number(input,strict=TRUE),gold)
  expect_identical(parse_cn_quantity(input,strict=TRUE)$value,gold)
  range <- parse_cn_range(input,strict=TRUE)
  expect_identical(range$lower,gold)
  expect_identical(range$upper,gold)
  expect_true(all(range$lower_inclusive & range$upper_inclusive))
  expect_identical(parse_cn_number(c('3','3百元','1.5'),unit='百元',strict=TRUE),c(300,300,150))
  expect_identical(parse_cn_number(factor(c('3','3百元')),unit='百元'),c(300,300))
  expect_identical(parse_cn_number(c(a=1,b=NA_real_),unit='百元'),c(a=100,b=NA_real_))
  expect_identical(parse_cn_number(c('3百元','2'),na='３百元',unit='百元'),c(NA_real_,200))
  expect_identical(1/parse_cn_number('-0百元'),-Inf)
})

test_that('hundred yuan propagates to qualified quantities and range endpoints', {
  quantity <- parse_cn_quantity(c('约3百元','不小于3百元','50余百元'),strict=TRUE)
  expect_identical(quantity$value,c(300,300,5000))
  expect_identical(quantity$qualifier,c('approx','at_least','greater_than'))
  range <- parse_cn_range(c('3-5百元','3百元-5','3百元-1千元','大于3百元'),strict=TRUE)
  expect_identical(range$lower,rep(300,4L))
  expect_identical(range$upper,c(500,500,1000,Inf))
  expect_identical(range$lower_inclusive,c(TRUE,TRUE,TRUE,FALSE))
  expect_identical(range$upper_inclusive,c(TRUE,TRUE,TRUE,FALSE))
  expect_error(parse_cn_range('3百元-5%',strict=TRUE),'incompatible units')
})

test_that('hundred yuan rejects malformed syntax and conflicting headers', {
  bad <- c('3百','3百块','3百元元','3百元%','1 2百元','1万200百元','3百元abc')
  for (parser in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    result <- suppressWarnings(parser(bad))
    expect_identical(cn_problems(result)$index,seq_along(bad))
    expect_identical(cn_problems(result)$value,bad)
    expect_error(parser(bad,strict=TRUE),'positions 1, 2, 3, 4, 5')
  }
  parsed <- suppressWarnings(parse_cn_number(c('2','3百元','4千元','5%','暂无'),unit='百元'))
  expect_identical(as.numeric(parsed),c(200,300,NA_real_,NA_real_,NA_real_))
  expect_identical(cn_problems(parsed)$index,3:4)
  expect_identical(cn_problems(parsed)$value,c('4千元','5%'))
  expect_error(parse_cn_number('3百元',unit='千元',strict=TRUE),'conflicts')
  expect_error(parse_cn_number('1亿2万',unit='百元',strict=TRUE),'table-header')
})

test_that('hundred-yuan native conversion retains boundary and malformed-text safety', {
  native <- .Call(cncleanr:::C_simple_numbers,c('3百元','1.5百元','1百','1百元x','1百元%'),NA_real_)
  expect_identical(native,c(300,150,NA_real_,NA_real_,NA_real_))
  expect_identical(.Call(cncleanr:::C_simple_numbers,c('3','3百元'),100),c(300,300))
  expect_identical(parse_cn_number(c('1e-325百元','1e306百元')),c(1e-323,1e308))
  expect_identical(parse_cn_number('1e-325',unit='百元'),1e-323)
  expect_error(parse_cn_number('1e-330百元',strict=TRUE),'underflows')
  expect_error(parse_cn_number('1e307百元',strict=TRUE),'finite double range')
  for (bytes in list(c(0xe7),c(0xe7,0x99),c(0xe7,0x99,0xbe,0xe5),c(0xe7,0x99,0xbe,0xe5,0x85))) {
    text <- paste0('1',rawToChar(as.raw(bytes)))
    Encoding(text) <- 'UTF-8'
    expect_error(parse_cn_number(c('3百元',text)),'Input `x` at position 2')
  }
})
