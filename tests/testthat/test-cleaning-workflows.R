test_that('the runnable workflow preserves source provenance across all parsers', {
  example <- system.file('examples', 'chunked-cleaning.R', package = 'cncleanr', mustWork = TRUE)
  expect_silent(result <- source(example, local = new.env(), encoding = 'UTF-8')$value)
  expect_identical(names(result), c('number', 'quantity', 'range'))
  for (kind in names(result)) {
    expect_identical(result[[kind]]$review$source_row, c(2L, 5L))
    expect_identical(result[[kind]]$selected_review$id, c('0005', '0002', '0005'))
    expect_identical(which(result[[kind]]$status == 'missing'), c(3L, 7L))
  }
})

test_that('irregular chunks retain whole-input values and original diagnostic rows', {
  exact <- c('3万', '12.5%', '1 234', '-0', '1e-300', NA, '暂无', 'bad', '1 2')
  gold <- c(30000, .125, 1234, -0, 1e-300, NA_real_, NA_real_, NA_real_, NA_real_)
  inputs <- list(exact, c('约3万', '10万+', '3-5万', '小于2万', exact))
  batches <- list(list(1:3, integer(), 4:9),
                  list(c(9L,2L,8L), c(1L,9L), integer(), c(7L,6L,5L,4L,3L)))
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    whole <- suppressWarnings(parser(exact))
    value <- if (is.data.frame(whole)) whole[[1L]] else as.numeric(whole)
    expect_identical(value, gold)
    expect_identical(cn_problems(whole)$index, 8:9)
    for (input in inputs) {
      whole <- suppressWarnings(parser(input))
      columns <- if (is.data.frame(whole)) names(whole) else 'value'
      for (parts in c(batches, list(list(integer(), seq_along(input), integer())))) {
        # The short schedules deliberately select only a subset of the longer input.
        source_rows <- unlist(parts, use.names=FALSE)
        chunks <- lapply(parts, function(rows) {
          parsed <- suppressWarnings(parser(input[rows]))
          problems <- cn_problems(parsed)
          problems$index <- rows[problems$index]
          values <- if (is.data.frame(parsed)) parsed else data.frame(value=as.numeric(parsed))
          attr(values,'problems') <- NULL
          list(values=values, problems=problems)
        })
        values <- do.call(rbind, lapply(chunks, `[[`, 'values'))
        problems <- do.call(rbind, lapply(chunks, `[[`, 'problems'))
        expected <- cn_subset(whole, source_rows)
        for (column in columns) {
          wanted <- if (is.data.frame(expected)) expected[[column]] else as.numeric(expected)
          expect_identical(values[[column]], wanted)
        }
        expected_problems <- cn_problems(expected)
        expect_identical(problems$index, source_rows[expected_problems$index])
        expect_identical(problems$value, expected_problems$value)
        expect_identical(problems$reason, expected_problems$reason)
      }
    }
  }
})

test_that('RDS preserves boundary values and diagnostics that CSV cannot serialize', {
  directory <- tempfile('cncleanr-roundtrip-')
  dir.create(directory)
  on.exit(unlink(directory, recursive=TRUE))
  for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
    for (input in list(c(1+2^-52, -0, NA_real_, NaN, Inf, -Inf),
                       c('大于3万', '小于3万', 'bad,"\nline', NA, '暂无'))) {
      parsed <- suppressWarnings(parser(input))
      file <- file.path(directory, 'parsed.rds')
      saveRDS(parsed, file)
      back <- readRDS(file)
      expect_identical(back, parsed)
      expect_identical(cn_problems(back), cn_problems(parsed))
      if (is.numeric(input)) {
        value <- if (is.data.frame(back)) back[[1L]] else back
        expect_identical(1/value[2L], -Inf)
        expect_true(is.nan(value[4L]))
      }
    }
  }
})
