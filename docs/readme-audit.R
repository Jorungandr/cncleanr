# Rscript docs/readme-audit.R [installed-library] [optional-units-library]
# Execute literal README blocks in a disposable directory; never install packages.
(function() {
  args <- commandArgs(trailingOnly=TRUE)
  if (length(args)) .libPaths(c(normalizePath(args,mustWork=TRUE),.libPaths()))
  library(cncleanr)
  root <- getwd()
  blocks <- function(file) {
    lines <- readLines(file,encoding='UTF-8',warn=FALSE)
    starts <- which(lines=='```r')
    lapply(starts,function(start) {
      end <- which(lines=='```' & seq_along(lines)>start)[1L]
      stopifnot(!is.na(end))
      lines[seq.int(start+1L,end-1L)]
    })
  }
  chinese <- blocks('README.md')
  english <- blocks('README_EN.md')
  # Code, unlike prose, should not drift between the two language editions.
  canonical <- function(x) lapply(x,function(lines) lines[!grepl('^#',lines)])
  stopifnot(identical(canonical(chinese),canonical(english)))
  directory <- tempfile('cncleanr-readme-')
  dir.create(directory)
  on.exit({setwd(root);unlink(directory,recursive=TRUE)})
  setwd(directory)
  for (edition in list(chinese=chinese,english=english)) {
    environment <- new.env(parent=globalenv())
    passed <- installs <- optional <- errors <- 0L
    for (lines in edition) {
      code <- paste(lines,collapse='\n')
      if (grepl('install.packages|pak::pak',code)) {
        installs <- installs+1L
        next
      }
      if (grepl('units::',code) && !requireNamespace('units',quietly=TRUE)) {
        optional <- optional+1L
        next
      }
      if (identical(parse(text=code)[[1L]],
          quote(parse_cn_number(c('2万','abc'),strict=TRUE)))) {
        error <- tryCatch({eval(parse(text=code),environment);NULL},error=identity)
        stopifnot(inherits(error,'error'),grepl('positions 2',conditionMessage(error)))
        errors <- errors+1L
      } else {
        withCallingHandlers(invisible(capture.output(eval(parse(text=code),environment))),
          warning=function(w) stop(conditionMessage(w),call.=FALSE))
      }
      passed <- passed+1L
    }
    cat('PASS: literal README blocks:',passed,'including expected errors:',errors,
        '; installation blocks not executed:',installs,
        '; missing optional units blocks:',optional,'\n')
    stopifnot(errors==1L,installs==3L)
  }
})()
