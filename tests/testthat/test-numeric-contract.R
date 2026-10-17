test_that('numeric conversions retain the vector contract at every parser entry', (function() {
  table <- get('.__S3MethodsTable__.', envir=asNamespace('base'))
  method <- 'as.double.cncleanr_contract'
  stopifnot(!exists(method, envir=table, inherits=FALSE))
  on.exit(rm(list=method, envir=table))
  calls <- 0L
  converted <- NULL
  registerS3method('as.double', 'cncleanr_contract', function(x, ...) {
    calls <<- calls + 1L
    converted
  }, envir=asNamespace('base'))
  parsers <- list(parse_cn_number, parse_cn_quantity, parse_cn_range,
    function(x, ...) parse_cn_number(x, unit='万', ...))
  for (spss in c(FALSE, TRUE)) {
    input <- structure(c(a=1, b=2, c=3), class=c('cncleanr_contract',
      if (spss) 'haven_labelled_spss'), na_values=99)
    for (bad in list(42, 1:3, numeric(), c(1,2,3,4), 'wrong',
        rep(TRUE,3), list(1,2,3), matrix(as.double(1:3),nrow=1),
        structure(as.double(1:3),class='retained_class'))) {
      converted <- bad
      for (parser in parsers) {
        calls <- 0L
        expect_error(parser(input), 'plain double vector of the same length')
        expect_identical(calls, 1L)
      }
    }
    converted <- c(2,NA_real_,NaN)
    for (parser in parsers) {
      calls <- 0L
      result <- parser(input, strict=TRUE)
      expect_identical(if (is.data.frame(result)) nrow(result) else length(result), 3L)
      expect_identical(calls, 1L)
    }
  }
  converted <- numeric()
  empty <- structure(numeric(),class='cncleanr_contract')
  for (parser in parsers) {
    calls <- 0L
    result <- parser(empty)
    expect_identical(if (is.data.frame(result)) nrow(result) else length(result), 0L)
    expect_identical(calls, 1L)
  }
  converted <- c(Inf,-Inf,NaN)
  expect_identical(parse_cn_number(structure(1:3,class='cncleanr_contract')), converted)
  registerS3method('as.double', 'cncleanr_contract', function(x, ...) {
    warning('conversion warning', call.=FALSE)
    as.double(unclass(x))
  }, envir=asNamespace('base'))
  for (parser in parsers)
    expect_warning(parser(structure(1:3,class='cncleanr_contract')), 'conversion warning')
})())
