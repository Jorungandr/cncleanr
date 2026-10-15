# Rscript inst/examples/chunked-cleaning.R
# Synthetic example, not additional real-data coverage or a new package API.
(function() {
  library(cncleanr)
  directory <- tempfile('cncleanr-workflow-')
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  raw <- data.frame(id = sprintf('%04d', 1:8),
    text = c('3\u4e07', 'bad,"\nline', '\u6682\u65e0', '2\u4e07',
             '1 2', '1\u4e07', '-', '4\u4e07'), stringsAsFactors = FALSE)
  batches <- list(1:3, integer(), 4:6, 7:8)
  results <- list()
  for (kind in c('number', 'quantity', 'range')) {
    parser <- get(paste0('parse_cn_', kind), asNamespace('cncleanr'))
    # Extract problems before binding. Each batch maps through its source rows,
    # including empty and problem-free batches; never bind problem attributes.
    chunks <- lapply(batches, function(rows) {
      parsed <- suppressWarnings(parser(raw$text[rows]))
      problems <- cn_problems(parsed)
      source <- rows[problems$index]
      review <- data.frame(source_row = source, id = raw$id[source],
        original = raw$text[source], reason = problems$reason, stringsAsFactors = FALSE)
      values <- if (is.data.frame(parsed)) parsed else data.frame(value = as.numeric(parsed))
      attr(values, 'problems') <- NULL
      list(data = data.frame(source_row = rows, raw[rows, , drop = FALSE], values),
           problems = review)
    })
    combined <- do.call(rbind, lapply(chunks, `[[`, 'data'))
    review <- do.call(rbind, lapply(chunks, `[[`, 'problems'))
    rownames(combined) <- rownames(review) <- NULL
    whole <- suppressWarnings(parser(raw$text))
    original_problems <- cn_problems(whole)
    value_columns <- if (is.data.frame(whole)) names(whole) else 'value'
    for (column in value_columns) {
      expected <- if (is.data.frame(whole)) whole[[column]] else as.numeric(whole)
      stopifnot(identical(combined[[column]], expected))
    }
    stopifnot(identical(combined$source_row, 1:8),
      identical(review$source_row, c(2L, 5L)),
      identical(review$id, c('0002', '0005')),
      identical(review$original, original_problems$value),
      identical(review$reason, original_problems$reason))

    # Save review records BEFORE dropping NA: failures and ordinary missing
    # values both have NA numeric results, but only failures belong in review.
    primary <- combined[[value_columns[[1L]]]]
    status <- rep('parsed', nrow(raw))
    status[is.na(primary)] <- 'missing'
    status[review$source_row] <- 'needs_review'
    stopifnot(identical(status, c('parsed', 'needs_review', 'missing', 'parsed',
                                 'needs_review', 'parsed', 'missing', 'parsed')))
    combined$status <- status
    clean <- cn_subset(whole, which(status == 'parsed'))
    clean_value <- if (is.data.frame(clean)) clean[[1L]] else as.numeric(clean)
    stopifnot(identical(clean_value, c(30000, 20000, 10000, 40000)))

    # Track provenance through EVERY selection. Problem indices remain local
    # to the current result; repeated source rows must remain repeated.
    source_rows <- seq_len(nrow(raw))
    first <- c(8L, 5L, 2L, 6L, 3L, 5L, 1L)
    selected <- cn_subset(whole, first)
    source_rows <- source_rows[first]
    keep <- c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE)
    selected <- cn_subset(selected, keep)
    source_rows <- source_rows[keep]
    primary <- if (is.data.frame(selected)) selected[[1L]] else as.numeric(selected)
    ordering <- order(primary, na.last = TRUE)
    selected <- cn_subset(selected, ordering)
    source_rows <- source_rows[ordering]
    problems <- cn_problems(selected)
    selected_review <- data.frame(current_row = problems$index,
      source_row = source_rows[problems$index],
      id = raw$id[source_rows[problems$index]], original = problems$value,
      reason = problems$reason, stringsAsFactors = FALSE)
    stopifnot(identical(source_rows, c(6L, 1L, 8L, 5L, 2L, 5L)),
      identical(selected_review$current_row, 4:6),
      identical(selected_review$source_row, c(5L, 2L, 5L)),
      identical(selected_review$original, raw$text[c(5, 2, 5)]))

    # CSV does not serialize R attributes. Export values and review separately,
    # then read as text to preserve IDs, missing markers and multiline fields.
    tables <- list(values = combined, problems = review, selected_problems = selected_review)
    for (name in names(tables)) {
      file <- file.path(directory, paste0(kind, '-', name, '.csv'))
      write.csv(tables[[name]], file, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
      back <- read.csv(file, colClasses = 'character', na.strings = character(),
                       fileEncoding = 'UTF-8', check.names = FALSE)
      expected <- tables[[name]]
      stopifnot(identical(back$id, expected$id))
      if ('text' %in% names(back)) {
        stopifnot(identical(back$text, raw$text), identical(back$status, status),
                  identical(as.integer(back$source_row), expected$source_row))
        for (column in value_columns) {
          wanted <- expected[[column]]
          if (is.numeric(wanted)) {
            stopifnot(identical(as.double(back[[column]]), as.double(wanted)))
          } else if (is.logical(wanted)) {
            stopifnot(identical(as.logical(back[[column]]), wanted))
          } else {
            wanted[is.na(wanted)] <- ''
            stopifnot(identical(back[[column]], wanted))
          }
        }
      } else {
        stopifnot(identical(back$original, expected$original),
          identical(back$reason, expected$reason),
          identical(as.integer(back$source_row), expected$source_row))
      }
    }
    results[[kind]] <- list(status = status, review = review,
                            selected_review = selected_review, source_rows = source_rows)
  }
  results
})()
