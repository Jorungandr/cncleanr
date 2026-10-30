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
  # Execute literal tutorial code too. Business import examples use the small
  # attributed fixture, not an invented full snapshot or a network download.
  tutorials <- c('docs/financial-table-example.md', 'docs/financial-table-example_EN.md',
                 'docs/business-workflows.md', 'docs/business-workflows_EN.md')
  for (file in tutorials) {
    tutorial_directory <- file.path(directory, basename(file))
    dir.create(tutorial_directory)
    setwd(tutorial_directory)
    business <- grepl('business-workflows', file, fixed = TRUE)
    if (business) {
      inputs <- 'outputs/business-validation-2026-10-30'
      dir.create(inputs, recursive = TRUE)
      stopifnot(file.copy(file.path(root, 'docs/fixtures/business-cases.csv'),
                          file.path(inputs, 'cases.csv')))
    }
    environment <- new.env(parent = globalenv())
    passed <- installs <- 0L
    for (lines in blocks(file.path(root, file))) {
      code <- paste(lines, collapse = '\n')
      if (grepl('install.packages|pak::pak', code)) {
        installs <- installs + 1L
        next
      }
      withCallingHandlers(invisible(capture.output(eval(parse(text = code), environment))),
        warning = function(w) stop(conditionMessage(w), call. = FALSE))
      passed <- passed + 1L
    }
    if (business) {
      stopifnot(passed == 2L, installs == 0L, nrow(environment$cases) == 22L,
                !anyDuplicated(environment$cases$case_id))
    } else {
      stopifnot(passed == 3L, installs == 1L)
      exported <- read.csv('cleaned.csv', colClasses = 'character',
        na.strings = character(), check.names = FALSE, fileEncoding = 'UTF-8')
      review <- read.csv('problems.csv', colClasses = 'character',
        na.strings = character(), check.names = FALSE, fileEncoding = 'UTF-8')
      exported_value <- exported$value
      exported_value[exported_value == 'NA'] <- NA_character_
      exported_value <- withCallingHandlers(as.double(exported_value),
        warning = function(w) stop(conditionMessage(w), call. = FALSE))
      stopifnot(identical(exported$text, environment$raw$text),
                identical(exported$source_row, as.character(environment$raw$source_row)),
                identical(exported$output_unit, environment$cleaned$output_unit),
                identical(review$source_row, c('6', '7')),
                identical(review$text, environment$problem_rows$text),
                identical(review$reason, environment$problem_rows$reason),
                isTRUE(all.equal(exported_value, environment$cleaned$value)))
    }
    cat('PASS: literal tutorial:', file, '; runnable blocks:', passed,
        '; installation blocks not executed:', installs, '\n')
  }
})()
