test_that('SPSS metadata missingness is respected without external packages', {
  fixtures <- list(
    structure(c(a=1,b=97,c=99,d=NA_real_,e=NaN),class='haven_labelled_spss',na_values=c(97,99)),
    structure(c(1,96,97,98,99,100,NA_real_),class='haven_labelled_spss',na_range=c(97,99)),
    structure(c(1,97,98,99,100),class='haven_labelled_spss',na_values=100,na_range=c(97,99)),
    structure(c(a='3\u4e07',b='secret',c='bad',d=NA_character_),
      class='haven_labelled_spss',na_values='secret'),
    structure(setNames(numeric(),character()),class='haven_labelled_spss',na_values=99),
    structure(character(),class='haven_labelled_spss',na_values='secret')
  )
  expected <- list(c(a=1,b=NA_real_,c=NA_real_,d=NA_real_,e=NaN),
    c(1,96,NA_real_,NA_real_,NA_real_,100,NA_real_),
    c(1,NA_real_,NA_real_,NA_real_,NA_real_),
    c(a='3\u4e07',b=NA_character_,c='bad',d=NA_character_),
    setNames(numeric(),character()),character())
  for(i in seq_along(fixtures)) {
    for(f in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
      expect_identical(suppressWarnings(f(fixtures[[i]])),suppressWarnings(f(expected[[i]])))
      if(i != 4) expect_silent(f(fixtures[[i]],strict=TRUE))
    }
    expect_identical(suppressWarnings(parse_cn_number(fixtures[[i]],unit='万')),
                     suppressWarnings(parse_cn_number(expected[[i]],unit='万')))
  }
  x <- structure(c(1,97,Inf),class='haven_labelled_spss',na_values=c(97,Inf))
  expect_identical(parse_cn_number(x,unit='万',strict=TRUE),c(10000,NA_real_,NA_real_))
  text <- fixtures[[4]]
  for(f in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    result <- suppressWarnings(f(text))
    expect_identical(cn_problems(result)$index,3L)
    expect_identical(cn_problems(result)$value,'bad')
    expect_error(f(text,strict=TRUE),'positions 3')
    expect_identical(f(text,na=c('bad'),strict=TRUE),f(expected[[4]],na='bad',strict=TRUE))
    for(range in list(1,c(99,97),c(NA,99),c('a','z'))) {
      invalid <- structure(1,class='haven_labelled_spss',na_range=range)
      expect_error(f(invalid),'na_range',fixed=TRUE)
    }
  }
})

test_that('parsers reject units objects before dropping their meaning', {
  for(f in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    for(values in list(c(1,2),numeric(),c(NA_real_,Inf))) {
      x <- structure(values,class='units',units='m')
      for(strict in c(FALSE,TRUE)) expect_error(f(x,strict=strict),'drop_units',fixed=TRUE)
    }
  }
  expect_error(parse_cn_number(structure(1,class='units',units='1'),unit='万'),'drop_units',fixed=TRUE)
  expect_identical(parse_cn_number(c(1,2)),c(1,2))
})
