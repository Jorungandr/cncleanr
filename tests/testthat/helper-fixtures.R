read_cn_fixture <- function(filename) {
  utils::read.delim(
    testthat::test_path("fixtures", filename),
    sep = "\t",
    quote = "",
    comment.char = "",
    colClasses = "character",
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fill = TRUE,
    fileEncoding = "UTF-8"
  )
}

fixture_double <- function(x) {
  x[x == ""] <- NA_character_
  as.double(x)
}

fixture_logical <- function(x) {
  x[x == ""] <- NA_character_
  as.logical(x)
}
