# Rscript docs/table-cleaning-audit.R <installed-library>
source('docs/audit-setup.R')
source('docs/table-cleaning.R',encoding='UTF-8')
(function() {
  directory <- tempfile('cncleanr-table-audit-')
  dir.create(directory)
  on.exit(unlink(directory,recursive=TRUE))
  input <- file.path(directory,'input.csv')
  raw <- data.frame(id=c('0001','0001','0003','0004'),
    amount=c('3','bad,"\nline','暂无','4百元'),
    estimate=c('约3万','5万+','暂无','wrong'),
    interval=c('大于3','3-5','暂无','bad'),stringsAsFactors=FALSE)
  spec <- data.frame(column=c('amount','estimate','interval'),
    parser=c('number','quantity','range'),unit=c('百元','','千元'),stringsAsFactors=FALSE)
  write.csv(raw,input,row.names=FALSE,fileEncoding='UTF-8')
  run <- function(name,chunk=10000L,configuration=spec)
    clean_cn_csv(input,configuration,file.path(directory,name),id_column='id',chunk_size=chunk)
  full <- run('whole')
  stopifnot(identical(full$cleaned$amount__value,c(300,NA,NA,400)),
    identical(full$cleaned$estimate__value,c(30000,50000,NA,NA)),
    identical(full$cleaned$estimate__qualifier,c('approx','at_least',NA,NA)),
    identical(full$cleaned$interval__lower,c(3000,3000,NA,NA)),
    identical(full$cleaned$interval__upper,c(Inf,5000,NA,NA)),
    identical(full$cleaned$interval__lower_inclusive,c(FALSE,TRUE,NA,NA)),
    identical(full$cleaned$interval__upper_inclusive,c(FALSE,TRUE,NA,NA)),
    identical(full$review$source_row,c(2L,4L,4L)),
    identical(full$review$id,c('0001','0004','0004')),
    identical(full$review$field,c('amount','estimate','interval')),
    identical(full$review$raw,c(raw$amount[2],raw$estimate[4],raw$interval[4])),
    identical(as.double(unlist(full$summary[c('total','parsed','missing','failed')])),
      c(4,4,4,2,2,2,1,1,1,1,1,1)),
    sum(full$reasons$count)==3)
  for (chunk in c(1L,2L,3L,20L,.Machine$integer.max))
    stopifnot(identical(run(paste0('chunk-',chunk),chunk),full))
  stopifnot(identical(readRDS(file.path(directory,'whole','result.rds')),full))
  for (name in c('cleaned','review','summary','reasons')) {
    back <- read.csv(file.path(directory,'whole',paste0(name,'.csv')),
      colClasses='character',na.strings=character(),check.names=FALSE,fileEncoding='UTF-8')
    stopifnot(identical(names(back),names(full[[name]])),nrow(back)==nrow(full[[name]]))
    for (column in names(full[[name]])[vapply(full[[name]],is.character,logical(1))]) {
      wanted <- full[[name]][[column]]
      wanted[is.na(wanted)] <- ''
      stopifnot(identical(back[[column]],wanted))
    }
    for (column in names(full[[name]])[vapply(full[[name]],is.numeric,logical(1))])
      stopifnot(isTRUE(all.equal(as.double(back[[column]]),as.double(full[[name]][[column]]),
                                tolerance=1e-12)))
    for (column in names(full[[name]])[vapply(full[[name]],is.logical,logical(1))])
      stopifnot(identical(as.logical(back[[column]]),full[[name]][[column]]))
  }
  bad <- function(code) inherits(tryCatch(force(code),error=identity),'error')
  stopifnot(bad(run('whole')),bad(run('fractional',1.5)),bad(run('zero',0)),
    !file.exists(file.path(directory,'fractional')))
  wrong <- spec
  wrong$unit[1] <- '百'
  stopifnot(bad(run('wrong-unit',configuration=wrong)),!file.exists(file.path(directory,'wrong-unit')))
  wrong <- spec
  wrong$column[2] <- wrong$column[1]
  stopifnot(bad(run('duplicate-config',configuration=wrong)))
  wrong <- spec
  wrong$column[1] <- 'unknown'
  stopifnot(bad(run('unknown',configuration=wrong)))
  collision <- raw
  collision$amount__value <- 'keep'
  write.csv(collision,input,row.names=FALSE,fileEncoding='UTF-8')
  stopifnot(bad(run('collision')),!file.exists(file.path(directory,'collision')))
  for (name in c('empty','parsed','missing','failed')) {
    value <- switch(name,empty=character(),parsed=c('1','2'),missing=c('暂无','-'),failed=c('bad','wrong'))
    data <- data.frame(id=rep('0001',length(value)),amount=value,stringsAsFactors=FALSE)
    write.csv(data,input,row.names=FALSE,fileEncoding='UTF-8')
    result <- run(name,configuration=spec[1,,drop=FALSE])
    stopifnot(nrow(result$cleaned)==length(value),
      nrow(result$review)==if(name=='failed') 2L else 0L,
      result$summary$total==length(value),
      result$summary$missing==if(name=='missing') 2 else 0,
      result$summary$failed==if(name=='failed') 2 else 0)
  }
  write.csv(raw,input,row.names=FALSE,fileEncoding='UTF-8')
  broken <- clean_cn_csv
  fault <- new.env(parent=environment(clean_cn_csv))
  fault$saveRDS <- function(...) stop('Injected export failure.')
  environment(broken) <- fault
  files_before <- list.files(directory,all.files=TRUE)
  stopifnot(bad(broken(input,spec,file.path(directory,'failed-export'),id_column='id')),
    !file.exists(file.path(directory,'failed-export')),
    identical(list.files(directory,all.files=TRUE),files_before),
    identical(readRDS(file.path(directory,'whole','result.rds')),full))
  without_id <- clean_cn_csv(input,spec,file.path(directory,'without-id'))
  stopifnot(all(is.na(without_id$review$id)))
  for (chunk in list(NA_real_,Inf,TRUE,c(1L,2L),matrix(1L,1L)))
    stopifnot(bad(clean_cn_csv(input,spec,file.path(directory,'bad-chunk'),chunk_size=chunk)),
              !file.exists(file.path(directory,'bad-chunk')))
  for (text in c('id,amount\n0001,"unterminated',
                 'id,amount\n0001,3,4',
                 'id,amount,extra\n0001,3')) {
    writeLines(text,input,useBytes=TRUE)
    stopifnot(bad(run('malformed',configuration=spec[1,,drop=FALSE])),
              !file.exists(file.path(directory,'malformed')))
  }
  writeBin(c(charToRaw('id,amount\n0001,'),as.raw(c(0xc3,0x28))),input)
  stopifnot(bad(run('bad-encoding',configuration=spec[1,,drop=FALSE])),
            !file.exists(file.path(directory,'bad-encoding')))
  writeBin(c(as.raw(c(0xef,0xbb,0xbf)),charToRaw('id,amount\n0001,3\n')),input)
  bom <- run('utf8-bom',configuration=spec[1,,drop=FALSE])
  stopifnot(identical(bom$cleaned$id,'0001'),identical(bom$cleaned$amount__value,300))
  verify_business <- function(file,label) {
    cases <- read.csv(file,colClasses='character',na.strings=character(),
                      check.names=FALSE,fileEncoding='UTF-8')
    cases <- cases[cases$expected_status!='business_review',,drop=FALSE]
    groups <- split(seq_len(nrow(cases)),interaction(cases$parser,cases$parser_unit,drop=TRUE))
    for (i in seq_along(groups)) {
      rows <- groups[[i]]
      data <- cases[rows,,drop=FALSE]
      write.csv(data,input,row.names=FALSE,fileEncoding='UTF-8')
      configuration <- data.frame(column='parse_input',parser=data$parser[1],
        unit=data$parser_unit[1],stringsAsFactors=FALSE)
      result <- clean_cn_csv(input,configuration,file.path(directory,paste0(label,'-',i)),
                             id_column='case_id',chunk_size=137L)
      same_numbers <- function(actual,expected) {
        gold <- suppressWarnings(as.double(expected))
        stopifnot(identical(is.na(actual),is.na(gold)))
        present <- which(!is.na(gold))
        same <- actual[present]==gold[present]
        finite <- is.finite(actual[present]) & is.finite(gold[present])
        same[finite] <- abs(actual[present][finite]-gold[present][finite]) <=
          1e-12*pmax(1,abs(gold[present][finite]))
        all(same)
      }
      range <- data$parser[1]=='range'
      primary <- if(range) result$cleaned$parse_input__lower else result$cleaned$parse_input__value
      stopifnot(same_numbers(primary,data$expected_value),
        identical(result$cleaned$case_id,data$case_id),
        identical(result$cleaned$raw_input,data$raw_input),
        identical(result$cleaned$parse_input__status,
          unname(c(parsed='parsed',missing='missing',reject='needs_review')[data$expected_status])),
        identical(result$review$source_row,which(data$expected_status=='reject')),
        identical(result$review$id,data$case_id[data$expected_status=='reject']))
      if (range) stopifnot(same_numbers(result$cleaned$parse_input__upper,data$expected_upper),
        all(result$cleaned$parse_input__lower_inclusive[data$expected_status=='parsed']),
        all(result$cleaned$parse_input__upper_inclusive[data$expected_status=='parsed']))
      if (data$parser[1]=='quantity') {
        wanted <- data$expected_qualifier
        wanted[wanted==''] <- NA_character_
        stopifnot(identical(result$cleaned$parse_input__qualifier,wanted))
      }
    }
    cat('PASS:',nrow(cases),label,'source-derived parser fields through configured CSV workflow\n')
  }
  verify_business('docs/fixtures/business-cases.csv','offline')
  if (length(args)>1L) verify_business(args[2L],'retained')
  cat('PASS: configurable table arithmetic, diagnostics, CSV/RDS, chunks and edge cases\n')
})()
