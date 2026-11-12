# Rscript docs/business-boundary-audit.R <installed-library>
source('docs/audit-setup.R')
(function() {
  directory <- tempfile('cncleanr-business-boundaries-')
  dir.create(directory)
  on.exit(unlink(directory,recursive=TRUE))
  schema <- names(read.csv('docs/fixtures/business-cases.csv',nrows=0,
    colClasses='character',check.names=FALSE,fileEncoding='UTF-8'))
  input <- c('大于3','不小于3','小于3','不大于3','小于-3','3%-5%',
             '3','3','3','暂无','暂无','暂无','bad,"\nline','bad','bad','待人工确认')
  cases <- as.data.frame(setNames(rep(list(rep('',length(input))),length(schema)),schema),
                         stringsAsFactors=FALSE)
  cases$case_id <- sprintf('%04d',seq_along(input))
  cases$domain <- 'synthetic_boundaries'
  cases$source <- 'synthetic workflow regression'
  cases$source_row <- as.character(seq_along(input))
  cases$record_id <- cases$case_id
  cases$field <- 'amount'
  cases$raw_input <- cases$parse_input <- input
  cases$parser <- c(rep('range',6),'number','quantity','range',
                    'number','quantity','range','number','quantity','range','range')
  cases$expected_status <- c(rep('parsed',9),rep('missing',3),rep('reject',3),'business_review')
  cases$expected_value <- c('3','3','-Inf','-Inf','-Inf','.03','3','3','3',rep('',7))
  cases$expected_upper <- c('Inf','Inf','3','3','-3','.05','','','3',rep('',7))
  cases$expected_qualifier[8] <- 'exact'
  cases$expected_lower_inclusive <- c('FALSE','TRUE','FALSE','FALSE','FALSE','TRUE',rep('',10))
  cases$expected_upper_inclusive <- c('FALSE','FALSE','FALSE','TRUE','FALSE','TRUE',rep('',10))
  cases$review_note[16] <- 'Source needs human review.'
  fixture <- file.path(directory,'cases.csv')
  run <- function(data,name,success,failure_message='!any(x$outcome == "wrong")') {
    write.csv(data,fixture,row.names=FALSE,fileEncoding='UTF-8',na='')
    log <- file.path(directory,paste0(name,'.log'))
    output <- file.path(directory,name)
    status <- suppressWarnings(system2(file.path(R.home('bin'),'Rscript'),
      c(shQuote('docs/business-validation.R'),shQuote(dirname(find.package('cncleanr'))),
        shQuote(fixture),shQuote(output)),stdout=log,stderr=log))
    if (success && status!=0L) stop(paste(readLines(log,warn=FALSE),collapse='\n'))
    stopifnot(identical(status==0L,success))
    if (!success)
      stopifnot(any(grepl(failure_message,readLines(log,warn=FALSE),fixed=TRUE)))
    output
  }
  output <- run(cases,'valid',TRUE)
  back <- read.csv(file.path(output,'synthetic_boundaries-cleaned.csv'),
    colClasses='character',na.strings=character(),fileEncoding='UTF-8')
  review <- read.csv(file.path(output,'synthetic_boundaries-review.csv'),
    colClasses='character',na.strings=character(),fileEncoding='UTF-8')
  stopifnot(identical(back$case_id,cases$case_id),identical(back$raw_input,input),
            identical(review$case_id,cases$case_id[13:16]),
            identical(review$raw_input,input[13:16]),
            identical(as.double(back$value[1:6]),c(3,3,-Inf,-Inf,-Inf,.03)),
            identical(as.double(back$upper[1:6]),c(Inf,Inf,3,3,-3,.05)))
  for (name in c('parsed-only','missing-only','business-review-only')) {
    rows <- switch(name,'parsed-only'=1:9,'missing-only'=10:12,'business-review-only'=16L)
    output <- run(cases[rows,],name,TRUE)
    review <- read.csv(file.path(output,'synthetic_boundaries-review.csv'),
      colClasses='character',na.strings=character(),fileEncoding='UTF-8')
    wanted <- if(name=='business-review-only') cases$case_id[16] else character()
    stopifnot(identical(review$case_id,wanted))
  }
  wrong <- cases
  wrong$expected_lower_inclusive[1] <- 'TRUE'
  run(wrong,'wrong-inclusivity',FALSE)
  wrong <- cases
  wrong$expected_upper[1] <- '-Inf'
  run(wrong,'wrong-infinity-sign',FALSE)
  wrong <- cases
  wrong$expected_value[7] <- '4'
  run(wrong,'wrong-finite-value',FALSE)
  wrong <- cases
  wrong$expected_lower_inclusive[1] <- 'maybe'
  run(wrong,'invalid-inclusivity-flag',FALSE,
      'Expected inclusivity must be TRUE, FALSE or blank.')
  cat('PASS: 16 synthetic business boundary cases, 3 export scenarios and 4 negative validation probes\n')
})()
