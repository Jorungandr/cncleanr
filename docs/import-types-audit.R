# Rscript docs/import-types-audit.R <cncleanr-library> <optional-test-library>
# Local optional audit, deliberately not a package/runtime dependency.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==2L)
.libPaths(c(normalizePath(args[[2]],mustWork=TRUE),.libPaths()))
library(cncleanr,lib.loc=normalizePath(args[[1]],mustWork=TRUE))
stopifnot(requireNamespace('haven',quietly=TRUE),requireNamespace('units',quietly=TRUE),
          requireNamespace('bit64',quietly=TRUE))
for(p in c('cncleanr','haven','units','bit64')) cat(p,as.character(packageVersion(p)),'\n')
checks <- 0L
check <- function(ok,label) {
  checks <<- checks+1L
  if(!isTRUE(ok)) stop(label,call.=FALSE)
}
fixtures <- list(
  haven::labelled_spss(c(1,97,99,NA,NaN),na_values=c(97,99)),
  haven::labelled_spss(c(1,96,97,98,99,100,NA),na_range=c(97,99)),
  haven::labelled_spss(c(1,97,98,99,100),na_values=100,na_range=c(97,99)),
  haven::labelled_spss(c('3万','secret','bad',NA),na_values='secret'),
  haven::labelled_spss(numeric(),na_values=99),
  haven::labelled_spss(character(),na_values='secret'))
expected <- list(c(1,NA_real_,NA_real_,NA_real_,NaN),
  c(1,96,NA_real_,NA_real_,NA_real_,100,NA_real_),
  c(1,NA_real_,NA_real_,NA_real_,NA_real_),
  c('3万',NA_character_,'bad',NA_character_),numeric(),character())
for(i in seq_along(fixtures)) {
  x <- fixtures[[i]]
  names(x) <- sprintf('row%d',seq_along(x))
  names(expected[[i]]) <- names(x)
  for(f in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    check(identical(suppressWarnings(f(x)),suppressWarnings(f(expected[[i]]))),
          paste('SPSS fixture',i))
    check(identical(cn_problems(suppressWarnings(f(x)))$index,
      if(i==4L) 3L else integer()),'original diagnostic positions')
  }
  check(identical(suppressWarnings(parse_cn_number(x,unit='万')),
    suppressWarnings(parse_cn_number(expected[[i]],unit='万'))),'SPSS header scaling')
}
tagged <- haven::labelled(c(1,haven::tagged_na('a'),haven::tagged_na('z')))
spss_tagged <- haven::labelled_spss(c(1,haven::tagged_na('a'),99),na_values=99)
for(f in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
  y <- f(tagged)
  value <- if(is.data.frame(y)) y[[1L]] else y
  check(identical(haven::na_tag(value),haven::na_tag(tagged)),'tagged NA payloads')
  y <- f(spss_tagged)
  value <- if(is.data.frame(y)) y[[1L]] else y
  check(identical(value[1],1) && identical(haven::na_tag(value)[2],'a') && is.na(value[3]),
        'SPSS tagged NA alongside user missing')
  check(identical(f(haven::labelled(c(1,2,NA),c(yes=1,no=2))),f(c(1,2,NA_real_))),
        'ordinary labels retain numeric codes')
  for(u in c('m','km','1')) {
    for(v in list(c(1,2,NA),numeric())) {
      x <- units::set_units(v,u,mode='standard')
      e <- tryCatch(f(x),error=identity)
      check(inherits(e,'error') && grepl('drop_units',conditionMessage(e),fixed=TRUE),
            'reject direct units input')
    }
  }
  exact <- bit64::as.integer64(c('30000',NA,'9007199254740991'))
  check(identical(f(exact),f(c(30000,NA_real_,2^53-1))),'exact bit64 values')
  warnings <- character()
  y <- withCallingHandlers(f(bit64::as.integer64('9007199254740993')),warning=function(w) {
    warnings <<- c(warnings,conditionMessage(w)); invokeRestart('muffleWarning')
  })
  check(any(grepl('precision lost',warnings,fixed=TRUE)),'bit64 precision warning not swallowed')
}
metres <- units::set_units(c(1000,2000),'m')
kilometres <- units::set_units(metres,'km')
check(identical(parse_cn_number(units::drop_units(metres)),c(1000,2000)),
      'explicit metre conversion')
check(identical(parse_cn_number(units::drop_units(kilometres)),c(1,2)),
      'explicit kilometre conversion')
cat('PASS:',checks,'real imported-type checks\n')
