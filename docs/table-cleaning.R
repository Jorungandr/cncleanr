# Repository example. Source explicitly from the checkout root.
clean_cn_csv <- function(input, spec, output_dir, id_column = NULL, chunk_size = 10000L) {
  scalar_text <- function(x) is.character(x) && length(x)==1L &&
    is.null(dim(x)) && !is.na(x) && nzchar(x)
  if (!scalar_text(input) || !file.exists(input) || dir.exists(input))
    stop('`input` must name an existing CSV file.',call.=FALSE)
  if (!scalar_text(output_dir) || file.exists(output_dir))
    stop('`output_dir` must name a new directory.',call.=FALSE)
  if (!is.data.frame(spec) || !setequal(names(spec),c('column','parser','unit')) ||
      ncol(spec)!=3L || nrow(spec)==0L ||
      any(!vapply(spec,function(column) is.character(column) && is.null(dim(column)),logical(1))) || anyNA(spec))
    stop('`spec` needs character columns column, parser and unit.',call.=FALSE)
  spec <- spec[,c('column','parser','unit'),drop=FALSE]
  rownames(spec) <- NULL
  if (any(!nzchar(spec$column)) || anyDuplicated(spec$column) ||
      any(!spec$parser %in% c('number','quantity','range')))
    stop('Configured columns must be unique and parsers must be number/quantity/range.',call.=FALSE)
  if (!is.null(id_column) && !scalar_text(id_column))
    stop('`id_column` must be NULL or one column name.',call.=FALSE)
  if (!is.numeric(chunk_size) || is.object(chunk_size) || length(chunk_size)!=1L ||
      !is.null(dim(chunk_size)) || is.na(chunk_size) || !is.finite(chunk_size) ||
      chunk_size<1 || chunk_size!=trunc(chunk_size) || chunk_size>.Machine$integer.max)
    stop('`chunk_size` must be a positive representable integer.',call.=FALSE)
  raw <- withCallingHandlers(
    read.csv(input,colClasses='character',na.strings=character(),fill=FALSE,
             check.names=FALSE,fileEncoding='UTF-8'),
    warning=function(w) stop(conditionMessage(w),call.=FALSE))
  if (.row_names_info(raw,1L)>0L)
    stop('CSV records have more fields than the header.',call.=FALSE)
  if (anyDuplicated(names(raw)) || any(!nzchar(names(raw))) ||
      !all(spec$column %in% names(raw)) ||
      (!is.null(id_column) && !id_column %in% names(raw)))
    stop('CSV columns must be uniquely named and contain the configured fields.',call.=FALSE)
  parsers <- lapply(spec$parser,function(kind)
    getExportedValue('cncleanr',paste0('parse_cn_',kind)))
  templates <- lapply(seq_len(nrow(spec)),function(i) {
    value <- parsers[[i]](character(),unit=if(spec$unit[i]=='') NULL else spec$unit[i])
    if (is.data.frame(value)) value else data.frame(value=as.numeric(value))
  })
  generated <- unlist(lapply(seq_len(nrow(spec)),function(i)
    paste0(spec$column[i],'__',c(names(templates[[i]]),'status'))),use.names=FALSE)
  if ('.source_row' %in% names(raw) || anyDuplicated(generated) || any(generated %in% names(raw)))
    stop('Generated output columns conflict with input names.',call.=FALSE)
  size <- nrow(raw)
  cleaned <- data.frame(.source_row=seq_len(size),raw,check.names=FALSE)
  review_parts <- reason_parts <- list()
  summary <- data.frame(field=spec$column,parser=spec$parser,unit=spec$unit,
    total=rep(0,nrow(spec)),parsed=rep(0,nrow(spec)),missing=rep(0,nrow(spec)),failed=rep(0,nrow(spec)))
  starts <- if(size) seq.int(1L,size,by=chunk_size) else integer()
  for (i in seq_len(nrow(spec))) {
    field <- spec$column[i]
    values <- lapply(templates[[i]],function(column) {
      result <- vector(typeof(column),size)
      result[] <- NA
      result
    })
    status <- rep('missing',size)
    reason_counts <- setNames(numeric(),character())
    for (start in starts) {
      rows <- seq.int(start,min(size,as.double(start)+chunk_size-1))
      parsed <- suppressWarnings(parsers[[i]](raw[[field]][rows],
        unit=if(spec$unit[i]=='') NULL else spec$unit[i]))
      problems <- cncleanr::cn_problems(parsed)
      report <- cncleanr::cn_summary(parsed)
      frame <- if(is.data.frame(parsed)) parsed else data.frame(value=as.numeric(parsed))
      for (column in names(values)) values[[column]][rows] <- frame[[column]]
      status[rows] <- ifelse(is.na(frame[[1L]]),'missing','parsed')
      if (nrow(problems)) {
        source_rows <- rows[problems$index]
        status[source_rows] <- 'needs_review'
        ids <- if(is.null(id_column)) rep(NA_character_,length(source_rows)) else raw[[id_column]][source_rows]
        review_parts[[length(review_parts)+1L]] <- data.frame(source_row=source_rows,
          id=ids,field=rep(field,length(source_rows)),raw=raw[[field]][source_rows],
          reason=problems$reason,stringsAsFactors=FALSE)
      }
      summary[i,c('total','parsed','missing','failed')] <-
        summary[i,c('total','parsed','missing','failed')] + report$counts
      keys <- report$reasons$reason
      reason_counts[setdiff(keys,names(reason_counts))] <- 0
      reason_counts[keys] <- reason_counts[keys] + report$reasons$count
    }
    for (column in names(values)) cleaned[[paste0(field,'__',column)]] <- values[[column]]
    cleaned[[paste0(field,'__status')]] <- status
    reason_parts[[i]] <- data.frame(field=rep(field,length(reason_counts)),
      reason=names(reason_counts),count=unname(reason_counts),stringsAsFactors=FALSE)
  }
  review <- data.frame(source_row=integer(),id=character(),field=character(),
    raw=character(),reason=character(),stringsAsFactors=FALSE)
  if (length(review_parts)) review <- do.call(rbind,review_parts)
  reasons <- do.call(rbind,reason_parts)
  rownames(review) <- rownames(reasons) <- NULL
  result <- list(cleaned=cleaned,review=review,summary=summary,reasons=reasons,spec=spec)
  parent <- dirname(output_dir)
  dir.create(parent,recursive=TRUE,showWarnings=FALSE)
  if (!dir.exists(parent)) stop('Output parent could not be created.',call.=FALSE)
  parent <- normalizePath(parent,mustWork=TRUE)
  target <- file.path(parent,basename(output_dir))
  staging <- tempfile('.cncleanr-staging-',tmpdir=parent)
  dir.create(staging)
  on.exit(if(dir.exists(staging)) unlink(staging,recursive=TRUE),add=TRUE)
  for (name in c('cleaned','review','summary','reasons'))
    write.csv(result[[name]],file.path(staging,paste0(name,'.csv')),
      row.names=FALSE,na='',fileEncoding='UTF-8')
  saveRDS(result,file.path(staging,'result.rds'))
  if (file.exists(target) || !file.rename(staging,target))
    stop('Results could not be published to the new output directory.',call.=FALSE)
  invisible(result)
}
