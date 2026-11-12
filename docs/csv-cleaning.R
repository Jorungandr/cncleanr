# Rscript docs/csv-cleaning.R [optional-library-path]
# Synthetic example; each run writes only to its own temporary directory.
args <- commandArgs(trailingOnly=TRUE)
if (length(args)) .libPaths(c(args[[1]], .libPaths()))
library(cncleanr)
output <- tempfile('cncleanr-csv-')
dir.create(output)
original <- data.frame(
  id=c('0001', '0002', '0003'),
  amount=c('316', '1 2', '暂无'),
  headcount=c('10536', 'bad', '0007'),
  share=c('11.81', '5%', '-'), stringsAsFactors=FALSE
)
input <- file.path(output, 'input.csv')
write.csv(original, input, row.names=FALSE, fileEncoding='UTF-8')
raw <- read.csv(input, colClasses='character', na.strings=character(),
                check.names=FALSE, fileEncoding='UTF-8')
stopifnot(identical(raw, original))
# Example helper for the character columns id, amount, headcount and share.
clean_csv_fields <- function(raw) {
  cleaned <- raw
  problem_parts <- list()
  for (field in c('amount', 'headcount', 'share')) {
    # The monetary column is in ten thousand yuan. Headcounts have no multiplier.
    # Share is defined in percentage points, so bare values receive an explicit %.
    text <- raw[[field]]
    if (field == 'share') {
      bare <- grepl('^[+-]?[0-9]+([.][0-9]+)?$', text)
      text[bare] <- paste0(text[bare], '%')
    }
    parsed <- suppressWarnings(parse_cn_number(text,
      unit=if (field == 'amount') '万元' else NULL))
    cleaned[[paste0(field, '_value')]] <- as.numeric(parsed)
    problems <- cn_problems(parsed)
    if (nrow(problems)) {
      rows <- problems$index
      problem_parts[[field]] <- data.frame(
        source_row=rows, id=raw$id[rows], field=field,
        original=raw[[field]][rows], reason=problems$reason,
        stringsAsFactors=FALSE
      )
    }
  }
  review <- data.frame(source_row=integer(),id=character(),field=character(),
                       original=character(),reason=character(),stringsAsFactors=FALSE)
  if (length(problem_parts)) review <- do.call(rbind,problem_parts)
  rownames(review) <- NULL
  cleaned$amount_unit <- rep('yuan',nrow(cleaned))
  cleaned$headcount_unit <- rep('persons',nrow(cleaned))
  cleaned$share_unit <- rep('proportion',nrow(cleaned))
  list(cleaned=cleaned,review=review)
}
result <- clean_csv_fields(raw)
cleaned <- result$cleaned
review <- result$review
stopifnot(identical(cleaned$id, c('0001', '0002', '0003')),
  isTRUE(all.equal(cleaned$amount_value, c(3160000, NA_real_, NA_real_))),
  isTRUE(all.equal(cleaned$headcount_value, c(10536, NA_real_, 7))),
  isTRUE(all.equal(cleaned$share_value, c(.1181, .05, NA_real_))),
  identical(review$source_row, c(2L, 2L)),
  identical(review$field, c('amount', 'headcount')),
  identical(review$original, c('1 2', 'bad')))
write.csv(cleaned, file.path(output, 'cleaned.csv'), row.names=FALSE,
          na='', fileEncoding='UTF-8')
write.csv(review, file.path(output, 'problems.csv'), row.names=FALSE,
          fileEncoding='UTF-8')
# Read exported text without automatic type conversion or implicit missing markers.
roundtrip <- read.csv(file.path(output, 'cleaned.csv'), colClasses='character',
                     na.strings=character(), fileEncoding='UTF-8')
stopifnot(identical(roundtrip[names(raw)], raw),
          isTRUE(all.equal(as.double(roundtrip$share_value), cleaned$share_value)),
          identical(read.csv(file.path(output, 'problems.csv'),
            colClasses='character', na.strings=character(), fileEncoding='UTF-8')$original,
            review$original))
print(cleaned)
print(review)
cat('PASS: import, parsing, review indices and CSV round-trip\n')
(function() {
  valid <- data.frame(id=c('0001','0001','0003'),amount=c('1','2','3'),
    headcount=c('1','2','3'),share=c('10','20','30'),stringsAsFactors=FALSE)
  missing <- failed <- valid
  for (field in c('amount','headcount','share')) {
    missing[[field]] <- c('暂无',NA_character_,'')
    failed[[field]] <- c('bad,"\nline','1 2','wrong')
  }
  scenarios <- list(empty=valid[integer(),],parsed=valid,missing=missing,
                    failed=failed,mixed=raw)
  numeric_columns <- c('amount_value','headcount_value','share_value')
  review_columns <- c('source_row','id','field','original','reason')
  for (name in names(scenarios)) {
    input <- scenarios[[name]]
    result <- clean_csv_fields(input)
    stopifnot(identical(names(result$review),review_columns),
              identical(result$cleaned$id,input$id))
    expected_failures <- switch(name,empty=0L,parsed=0L,missing=0L,failed=9L,mixed=2L)
    stopifnot(nrow(result$review)==expected_failures)
    if (name=='parsed') {
      stopifnot(identical(result$cleaned$amount_value,c(10000,20000,30000)),
                identical(result$cleaned$headcount_value,c(1,2,3)),
                identical(result$cleaned$share_value,c(.1,.2,.3)))
    }
    if (name %in% c('missing','failed'))
      stopifnot(all(is.na(result$cleaned[numeric_columns])))
    if (name=='failed')
      stopifnot(identical(result$review$source_row,rep(1:3,3)),
                identical(result$review$id,rep(input$id,3)),
                identical(result$review$field,rep(c('amount','headcount','share'),each=3)))
    for (table_name in names(result)) {
      table <- result[[table_name]]
      file <- file.path(output,paste0(name,'-',table_name,'.csv'))
      write.csv(table,file,row.names=FALSE,na='',fileEncoding='UTF-8')
      back <- read.csv(file,colClasses='character',na.strings=character(),
                       fileEncoding='UTF-8',check.names=FALSE)
      stopifnot(identical(names(back),names(table)),nrow(back)==nrow(table))
      for (column in names(table)[vapply(table,is.character,logical(1))]) {
        wanted <- table[[column]]
        wanted[is.na(wanted)] <- ''
        stopifnot(identical(back[[column]],wanted))
      }
      for (column in names(table)[vapply(table,is.numeric,logical(1))])
        stopifnot(isTRUE(all.equal(as.double(back[[column]]),as.double(table[[column]]),
                                  tolerance=1e-12)))
    }
    file <- file.path(output,paste0(name,'.rds'))
    saveRDS(result,file)
    stopifnot(identical(readRDS(file),result))
    batches <- if(nrow(input)) list(c(3L,1L),integer(),c(2L,1L)) else list(integer(),integer())
    source_rows <- unlist(batches,use.names=FALSE)
    chunks <- lapply(batches,function(rows) clean_csv_fields(input[rows,,drop=FALSE]))
    combined <- do.call(rbind,lapply(chunks,`[[`,'cleaned'))
    rownames(combined) <- NULL
    expected <- clean_csv_fields(input[source_rows,,drop=FALSE])
    rownames(expected$cleaned) <- NULL
    stopifnot(identical(combined,expected$cleaned))
    offsets <- c(0L,head(cumsum(lengths(batches)),-1L))
    reviews <- lapply(seq_along(chunks),function(i) {
      review <- chunks[[i]]$review
      review$current_row <- offsets[i] + review$source_row
      review$source_row <- batches[[i]][review$source_row]
      review
    })
    review <- do.call(rbind,reviews)
    expected$review$current_row <- expected$review$source_row
    expected$review$source_row <- source_rows[expected$review$source_row]
    review <- review[order(review$current_row,review$field),,drop=FALSE]
    wanted <- expected$review[order(expected$review$current_row,expected$review$field),,drop=FALSE]
    rownames(review) <- rownames(wanted) <- NULL
    stopifnot(identical(review,wanted))
  }
  cat('PASS: 5 CSV edge/export scenarios and 5 repeated/empty chunk schedules\n')
})()
cat('Temporary output directory:', output, '\n')
