#' Extract Problems From a cncleanr Result
#'
#' Returns parsing failures attached to an object produced by a cncleanr
#' parser. Successful results return an empty data frame with the same stable
#' schema.
#'
#' @param x An object returned by a cncleanr parsing function.
#'
#' @return A data frame with columns `index`, `value`, and `reason`.
#'
#' @examples
#' result <- suppressWarnings(parse_cn_number(c("bad", "2\u4e07")))
#' cn_problems(result)
#'
#' @export
cn_problems <- function(x) {
  problems <- attr(x, "problems", exact = TRUE)
  if (is.null(problems)) {
    return(empty_cn_problems())
  }
  problems
}

empty_cn_problems <- function() {
  data.frame(
    index = integer(),
    value = character(),
    reason = character(),
    stringsAsFactors = FALSE
  )
}

apply_cn_problems <- function(output, problems, strict) {
  if (nrow(problems) == 0L) {
    return(output)
  }

  problems <- problems[order(problems$index), , drop = FALSE]
  rownames(problems) <- NULL
  message <- format_cn_parse_failure(problems)
  if (strict) {
    stop(message, call. = FALSE)
  }

  attr(output, "problems") <- problems
  warning(message, call. = FALSE)
  output
}
