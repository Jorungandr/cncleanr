test_that('accounting endpoints preserve and inherit units inside their wrappers', {
  x <- c('(3万)-5万','(3万)-5千元','(3)-5万','(3万)-5',
         '(5万)-(3)','(5)-(3万)','(3百元)-5','(5%)-3%')
  r <- parse_cn_range(x,strict=TRUE)
  expect_identical(r$lower,c(-30000,-30000,-30000,-30000,-50000,-50000,-300,-.05))
  expect_identical(r$upper,c(50000,5000,50000,50000,-30000,-30000,500,.03))
  expect_true(all(r$lower_inclusive & r$upper_inclusive))
  expect_identical(parse_cn_range('（３万）－５万',strict=TRUE)$upper,50000)
  expect_identical(parse_cn_range('(1 234万)-2 345万',strict=TRUE)$upper,2345e4)
  expect_identical(parse_cn_range('(3)-5百元',unit='百元',strict=TRUE)$lower,-300)
  expect_error(parse_cn_range('(3千元)-5百元',unit='百元',strict=TRUE),'table-header')
  expect_error(parse_cn_range('(3%)-5元',strict=TRUE),'incompatible units')
  for (x in c('(1亿2万)-3','(3)-1亿2万','((3万))-5万','(-3)-5万','(3万)万-5万'))
    expect_error(parse_cn_range(x,strict=TRUE))
  for (na in c('(3)','(3万)'))
    expect_error(parse_cn_range('(3)-5万',na=na,strict=TRUE))
})

test_that('independent arithmetic covers signed accounting and shared-unit intervals', {
  cells <- expand.grid(coefficient=c(1,3,5),form=c('positive','negative','accounting'),
    suffix=c('','元','百元','千元','万','%'),stringsAsFactors=FALSE)
  body <- paste0(cells$coefficient,cells$suffix)
  cells$text <- ifelse(cells$form=='accounting',paste0('(',body,')'),
    paste0(ifelse(cells$form=='negative','-',''),body))
  cells$value <- cells$coefficient*ifelse(cells$form=='positive',1,-1)
  cells$scale <- c(1,1,100,1000,10000,.01)[match(cells$suffix,c('','元','百元','千元','万','%'))]
  grid <- expand.grid(left=seq_len(nrow(cells)),right=seq_len(nrow(cells)),
    separator=c('-','~','至'),stringsAsFactors=FALSE)
  left <- cells[grid$left,]; right <- cells[grid$right,]
  lscale <- ifelse(left$suffix=='' & right$suffix!='',right$scale,left$scale)
  rscale <- ifelse(right$suffix=='' & left$suffix!='',left$scale,right$scale)
  lower <- left$value*lscale; upper <- right$value*rscale
  incompatible <- left$suffix!='' & right$suffix!='' & xor(left$suffix=='%',right$suffix=='%')
  valid <- !incompatible & lower<=upper
  text <- paste0(left$text,grid$separator,right$text)
  parsed <- suppressWarnings(parse_cn_range(text))
  expect_identical(cn_problems(parsed)$index,which(!valid))
  expect_identical(parsed$lower[valid],lower[valid])
  expect_identical(parsed$upper[valid],upper[valid])
  expect_true(all(is.na(parsed[!valid,])))
  expect_true(all(parsed$lower_inclusive[valid] & parsed$upper_inclusive[valid]))
})

test_that('dimensioned inputs are rejected instead of silently flattened', {
  inputs <- list(matrix(1:4,2),matrix(c('1','2','3','4'),2),
    array(1:8,c(2,2,2)),array('3万',c(1,1,1)),matrix(numeric(),0,2))
  for (parser in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    for (x in inputs) {
      expect_error(parser(x),'without dimensions')
      expect_error(parser(x,unit='万'),'without dimensions')
    }
    expect_error(parser('3',na=matrix('NA',1)),'without dimensions')
    expect_error(parser(numeric(),na=array('NA',c(1,1,1))),'without dimensions')
    expect_identical(nrow(cn_problems(parser(c('1','暂无')))),0L)
  }
})

test_that('accounting repair preserves grouping, currency and original missing markers', {
  for (space in c(' ','\t','\n','\u00a0','\u202f','\u3000')) {
    good <- paste0(' (1',space,'234)-2',space,'345万元 ')
    r <- parse_cn_range(good,strict=TRUE)
    expect_identical(r$lower,-1234e4)
    expect_identical(r$upper,2345e4)
    expect_error(parse_cn_range(paste0('(1',space,'23)-2',space,'345万'),strict=TRUE),'grouping')
  }
  r <- parse_cn_range(c('(RMB3)-5万元','(人民币3万)-5','(3元)-5万元',
                         '(3万元)-5元','-5-(3万)'),strict=TRUE)
  expect_identical(r$lower,c(-30000,-30000,-3,-30000,-50000))
  expect_identical(r$upper,c(50000,50000,50000,5,-30000))
  for (x in c('(USD3万)-5万','((3))-5万','(3)万-5万','(1亿2万)-3'))
    expect_error(parse_cn_range(x,strict=TRUE))
  input <- c('（３万）-5万','3-5万','（３万）-5万')
  result <- suppressWarnings(parse_cn_range(input,na='(3万)'))
  expect_identical(cn_problems(result)$index,c(1L,3L))
  expect_identical(cn_problems(result)$value,input[c(1,3)])
})

test_that('summary rejects internally inconsistent quantity and range results', {
  for (x in list(data.frame(value=1,qualifier='nonsense'),
    data.frame(value=1,qualifier=NA_character_),data.frame(value=NA_real_,qualifier='exact'),
    data.frame(value=1,qualifier=I(matrix('exact',1))),
    data.frame(lower=5,upper=3,lower_inclusive=TRUE,upper_inclusive=TRUE),
    data.frame(lower=1,upper=2,lower_inclusive=NA,upper_inclusive=TRUE),
    data.frame(lower=NA_real_,upper=NA_real_,lower_inclusive=TRUE,upper_inclusive=TRUE),
    data.frame(lower=1,upper=1,lower_inclusive=FALSE,upper_inclusive=TRUE),
    data.frame(lower=1,upper=2,lower_inclusive=I(matrix(TRUE,1)),upper_inclusive=TRUE)))
    expect_error(cn_summary(x),'result')
  for (parser in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    for (input in list(numeric(),c(Inf,-Inf,NaN,NA_real_),c('3','bad','暂无'))) {
      result <- suppressWarnings(parser(input))
      expect_silent(cn_summary(result))
      expect_silent(cn_summary(cn_subset(result)))
    }
  }
  expect_identical(cn_summary(parse_cn_quantity(c('约3','大于5')))$counts$parsed,2L)
  expect_identical(cn_summary(parse_cn_range(c('大于3','不大于5')))$counts$parsed,2L)
})

test_that('independent scalar arithmetic covers currency signs magnitudes and qualifiers', {
  grid <- expand.grid(body=c('0','1','1.5','.25','1,234','1 234','1e2'),
    currency=c('','RMB','人民币','￥'),
    suffix=c('','元','百元','千元','万','万元','亿','亿元','万亿','万亿元','%'),
    form=c('positive','negative','accounting'),stringsAsFactors=FALSE)
  values <- c(0,1,1.5,.25,1234,1234,100)[match(grid$body,
    c('0','1','1.5','.25','1,234','1 234','1e2'))]
  scale <- c(1,1,100,1000,1e4,1e4,1e8,1e8,1e12,1e12,.01)[match(grid$suffix,
    c('','元','百元','千元','万','万元','亿','亿元','万亿','万亿元','%'))]
  gold <- values*scale*ifelse(grid$form=='positive',1,-1)
  valid <- !(grid$suffix=='%' & grid$currency!='')
  text <- paste0(grid$currency,grid$body,grid$suffix)
  text <- ifelse(grid$form=='accounting',paste0('(',text,')'),
    paste0(ifelse(grid$form=='negative','-',''),text))
  n <- suppressWarnings(parse_cn_number(text))
  expect_identical(cn_problems(n)$index,which(!valid))
  expect_equal(as.numeric(n)[valid],gold[valid],tolerance=1e-14)
  for (prefix in c('','约','大于','不小于','小于','不大于')) {
    q <- suppressWarnings(parse_cn_quantity(paste0(prefix,text)))
    expect_identical(cn_problems(q)$index,which(!valid))
    expect_equal(q$value[valid],gold[valid],tolerance=1e-14)
  }
  r <- suppressWarnings(parse_cn_range(text))
  expect_identical(cn_problems(r)$index,which(!valid))
  expect_equal(r$lower[valid],gold[valid],tolerance=1e-14)
  expect_equal(r$upper[valid],gold[valid],tolerance=1e-14)
  for (result in list(n,suppressWarnings(parse_cn_quantity(text)),r)) {
    expect_identical(cn_summary(result)$counts$failed,sum(!valid))
    expect_identical(cn_summary(cn_subset(result,rev(seq_along(text))))$counts$failed,sum(!valid))
  }
})
