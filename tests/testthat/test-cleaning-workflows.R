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
