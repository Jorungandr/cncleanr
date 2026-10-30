# Rscript docs/system-audit.R <installed-library> [optional-bit64-library]
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 1:2)
if (length(args) == 2L) .libPaths(c(normalizePath(args[[2]], mustWork = TRUE), .libPaths()))
library(cncleanr, lib.loc=normalizePath(args[[1]], mustWork = TRUE))
stopifnot(as.character(packageVersion('cncleanr')) == read.dcf('DESCRIPTION')[1L,'Version'])
checks <- 0L
check <- function(ok, label) {
  checks <<- checks + 1L
  if (!isTRUE(ok)) stop('Audit failed: ', label, call. = FALSE)
}
outcome <- function(f, x, ...) {
  tryCatch(suppressWarnings(f(x, ...)), error=function(e) list(error=conditionMessage(e)))
}
values <- function(x) {
  attr(x,'problems') <- NULL
  if (!is.data.frame(x)) names(x) <- NULL
  rownames(x) <- NULL
  x
}
set.seed(20261017)
grid <- expand.grid(prefix=c('', '-', '+', '(', 'RMB', '\u7ea6', '\u5927\u4e8e', '\u4e0d\u5c0f\u4e8e'),
  body=c('0','.25','1','1,234','1 234','1 23','1e-330','1e309','\uff11\uff12\uff0e\uff15','bad','NA'),
  suffix=c('', '\u4e07', '%', '\u5343\u5143', ')', '\u4ee5\u4e0a', '\u5de6\u53f3','+'),stringsAsFactors=FALSE)
corpus <- c(do.call(paste0,grid), NA_character_, '', '3-5\u4e07','3%-5\u5143',
  '1 234-2 345', '-1e-3--2e-4', '(3\u4e07)-5', '3-(5\u4e07)')
for(kind in c('number','quantity','range')) {
  f <- get(paste0('parse_cn_',kind))
  full <- outcome(f,corpus)
  check(!is.list(full) || is.data.frame(full),paste(kind,'batch error'))
  for(i in sample(seq_along(corpus),400)) {
    one <- outcome(f,corpus[i])
    cell <- if(is.data.frame(full)) full[i,,drop=FALSE] else full[i]
    check(identical(values(one),values(cell)),paste(kind,'scalar/batch',i))
    check(identical(nrow(cn_problems(one))>0,i %in% cn_problems(full)$index),paste(kind,'diagnostic',i))
  }
  check(identical(full,outcome(f,factor(corpus))),paste(kind,'factor'))
  selection <- sample(seq_along(corpus),300,replace=TRUE)
  sliced <- cn_subset(full,selection)
  reparsed <- outcome(f,corpus[selection])
  check(identical(values(sliced),values(reparsed)),paste(kind,'subset values'))
  check(identical(cn_problems(sliced),cn_problems(reparsed)),paste(kind,'subset diagnostics'))
  for(marker in list(character(),c('0','bad'),c('NA','\uff10','1 23'))) {
    repeated <- rep(corpus[seq(1,length(corpus),length.out=30)],50)
    a <- outcome(f,repeated,na=marker)
    b <- cn_subset(outcome(f,unique(repeated),na=marker),match(repeated,unique(repeated)))
    check(identical(values(a),values(b)),paste(kind,'duplicate values'))
    check(identical(cn_problems(a),cn_problems(b)),paste(kind,'duplicate diagnostics'))
  }
  for(x in list(as.Date('2026-01-01'),as.POSIXct('2026-01-01',tz='UTC'),
    as.difftime(2,units='hours'),TRUE,1+1i,as.raw(1),list('1'),NULL))
    check(!is.null(outcome(f,x)$error),paste(kind,'unsupported type error'))
}
cat('PASS:',checks,'generated consistency checks (not independent semantic gold cases).\n')
before <- checks
for (kind in c('number', 'quantity', 'range')) {
  f <- get(paste0('parse_cn_', kind))
  for (unit in c('百元', '千元', '万元')) {
    scale <- c(100, 1000, 10000)[match(unit, c('百元', '千元', '万元'))]
    conflict <- if (unit == '百元') '千元' else '百元'
    atom <- c('3', paste0('4', unit), 'bad', '999', '暂 无', '１２',
              NA_character_, '-0', '1e309', '1e-999', paste0('5', conflict), '1 2')
    input <- rep(atom, 400L)
    gold <- rep(c(3 * scale, 4 * scale, NA, NA, NA, 12 * scale,
                  NA, -0, NA, NA, NA, NA), 400L)
    failed <- rep(seq_along(atom) %in% c(3L, 9L, 10L, 11L, 12L), 400L)
    missing <- rep(seq_along(atom) %in% c(4L, 5L, 7L), 400L)
    marker <- c('９９９', '暂 无')
    full <- suppressWarnings(f(input, unit = unit, na = marker))
    primary <- if (is.data.frame(full)) full[[1L]] else as.numeric(full)
    label <- paste(kind, unit)
    check(identical(primary, gold), paste(label, 'independent header values'))
    check(identical(1 / primary, 1 / gold), paste(label, 'signed zero'))
    if (kind == 'quantity')
      check(identical(full$qualifier, ifelse(is.na(gold), NA_character_, 'exact')),
        paste(label, 'independent qualifiers'))
    if (kind == 'range') {
      check(identical(full$upper, gold), paste(label, 'independent upper bounds'))
      check(identical(full$lower_inclusive, ifelse(is.na(gold), NA, TRUE)),
        paste(label, 'independent lower inclusivity'))
      check(identical(full$upper_inclusive, ifelse(is.na(gold), NA, TRUE)),
        paste(label, 'independent upper inclusivity'))
    }
    check(identical(cn_problems(full)$index, which(failed)), paste(label, 'independent failures'))
    check(identical(cn_problems(full)$value, input[failed]), paste(label, 'original text'))
    report <- cn_summary(full)
    check(identical(as.double(unlist(report$counts)),
      as.double(c(length(input), sum(!failed & !missing), sum(missing), sum(failed)))),
      paste(label, 'independent summary'))
    good <- which(!failed)
    check(identical(values(f(input[good], unit = unit, na = marker, strict = TRUE)),
      values(cn_subset(full, good))), paste(label, 'strict valid rows'))
    error <- tryCatch(f(input[c(1L, 3L, 4L)], unit = unit, na = marker, strict = TRUE),
                      error = identity)
    check(inherits(error, 'error') && grepl('positions 2.', conditionMessage(error), fixed = TRUE),
      paste(label, 'strict original position'))
    schedules <- list(
      partition = list(integer(), 1L, 2:511, 512:1023, integer(), 1024:length(input)),
      repeated = list(c(length(input), 3L, 4L, 3L, 2L), integer(),
                      seq.int(1L, length(input), by = 7L), c(8L, 9L)))
    for (schedule in schedules) {
      source <- unlist(schedule, use.names = FALSE)
      chunks <- lapply(schedule, function(rows) {
        parsed <- suppressWarnings(f(input[rows], unit = unit, na = marker))
        problems <- cn_problems(parsed)
        problems$index <- rows[problems$index]
        data <- if (is.data.frame(parsed)) parsed else data.frame(value = as.numeric(parsed))
        attr(data, 'problems') <- NULL
        list(data = data, problems = problems)
      })
      data <- do.call(rbind, lapply(chunks, `[[`, 'data'))
      problems <- do.call(rbind, lapply(chunks, `[[`, 'problems'))
      expected <- cn_subset(full, source)
      wanted <- if (is.data.frame(expected)) values(expected) else data.frame(value = as.numeric(expected))
      check(identical(values(data), wanted), paste(label, 'chunked values'))
      check(identical(problems$index, source[failed[source]]), paste(label, 'chunked source rows'))
      check(identical(problems$value, input[source[failed[source]]]), paste(label, 'chunked original text'))
      check(identical(problems$reason, cn_problems(expected)$reason), paste(label, 'chunked reasons'))
    }
  }
}
cat('PASS:', checks - before, 'header/custom-missing/chunk workflow checks.\n')
if (requireNamespace('bit64', quietly=TRUE)) {
  before <- checks
  for (f in list(parse_cn_number,parse_cn_quantity,parse_cn_range)) {
    x <- suppressWarnings(f(c('bad','2','wrong')))
    for (selection in list(c(3,2,1,3),-1,c(0,-2),numeric(),c(1,1)))
      check(identical(cn_subset(x,bit64::as.integer64(selection)),cn_subset(x,selection)),
            'bit64 selection and diagnostic mapping')
    for (selection in list(NA,4,-4))
      check(inherits(tryCatch(cn_subset(x,bit64::as.integer64(selection)),error=identity),'error'),
            'bit64 invalid selector rejection')
    check(identical(f(bit64::as.integer64(c(30000,NA))),f(c(30000,NA_real_))),
          'bit64 numeric parser conversion')
  }
  check(identical(parse_cn_number(bit64::as.integer64(c(3,NA)),unit='万'),c(30000,NA_real_)),
        'bit64 header conversion')
  cat('PASS:',checks-before,'optional bit64',as.character(packageVersion('bit64')),'checks.\n')
} else cat('NOT TESTED: bit64 unavailable; optional checks omitted, not a pass.\n')
