#' Extract Problems From a cncleanr Result
#'
#' Returns parsing failures attached to an object produced by a cncleanr
#' parser. Successful results return an empty data frame with the same stable
#' schema.
#' Use [cn_subset()] to select or reorder rows with their diagnostics. Other
#' base R transformations may drop the attribute or retain stale indices.
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

#' Select Parsed Results With Their Problems
#'
#' Explicitly subsets or reorders an unmodified parser result and remaps its
#' problem indices to positions in the selected result. Repeated selections
#' repeat the corresponding problems. Ordinary `[` does not track problems.
#'
#' @param x An unmodified result from a cncleanr parser, or from `cn_subset()`.
#' @param rows Integer-valued numeric indices (positive, zero, or negative using
#'   base R rules), or a logical vector of exactly the input length/row count.
#'   Missing, nonfinite, fractional and out-of-range indices are rejected.
#'   Defaults to all rows. Use `integer()` to select no rows.
#'   Classed numeric indices use `as.double()` once before validation.
#' @return The selected numeric vector or data frame, without a new class.
#'   Problem indices refer to the selected result, not the original input.
#' @details Call this before other transformations. It cannot recover problems
#'   lost or made stale by ordinary subsetting, mutation, sorting or binding.
#'   It does not reparse values or emit another parsing warning.
#' @examples
#' result <- suppressWarnings(parse_cn_number(c("bad", "2", "wrong")))
#' selected <- cn_subset(result, c(3, 2, 1, 3))
#' cn_problems(selected)
#' cn_subset(result, !is.na(result))
#' @export
cn_subset <- function(x, rows) {
  problems <- cn_result_problems(x)
  frame <- is.data.frame(x)
  size <- if (frame) nrow(x) else length(x)
  if (missing(rows)) rows <- seq_len(size)
  if (!is.null(dim(rows)) ||
      (!is.numeric(rows) && !is.logical(rows)))
    stop("`rows` must contain numeric indices or a full-length logical selection.", call. = FALSE)
  if (is.numeric(rows) && is.object(rows)) {
    original_size <- length(rows)
    rows <- as.double(rows)
    if (!is.double(rows) || is.object(rows) || !is.null(dim(rows)) || length(rows) != original_size)
      stop("`rows` must convert to a plain double vector of the same length.", call. = FALSE)
  }
  if (anyNA(rows))
    stop("`rows` must not contain missing indices.", call. = FALSE)
  if ((is.logical(rows) && length(rows) != size) ||
      (is.numeric(rows) && any(!is.finite(rows) | rows != trunc(rows) | abs(rows) > size)))
    stop("`rows` must be full-length logicals or finite integer indices within the input.", call. = FALSE)
  selected <- seq_len(size)[rows]
  output <- if (frame) x[selected, , drop = FALSE] else x[selected]
  attr(output, "problems") <- NULL
  mapping <- match(selected, problems$index)
  retained <- which(!is.na(mapping))
  if (length(retained)) {
    problems <- problems[mapping[retained], , drop = FALSE]
    problems$index <- retained
    rownames(problems) <- NULL
    attr(output, "problems") <- problems
  }
  output
}

cn_result_problems <- function(x) {
  frame <- is.data.frame(x)
  if ((!frame && (!is.numeric(x) || !is.null(dim(x)))) ||
      (frame && !identical(names(x), c("value", "qualifier")) &&
       !identical(names(x), c("lower", "upper", "lower_inclusive", "upper_inclusive"))))
    stop("`x` must be an unmodified cncleanr numeric or data-frame result.", call. = FALSE)
  size <- if (frame) nrow(x) else length(x)
  problems <- cn_problems(x)
  if (!is.data.frame(problems) || !identical(names(problems), c("index", "value", "reason")) ||
      !is.numeric(problems$index) || anyNA(problems$index) || anyDuplicated(problems$index) ||
      any(problems$index < 1 | problems$index > size | problems$index != trunc(problems$index)))
    stop("`x` has invalid or stale problems; use the original parser result.", call. = FALSE)
  problems
}

# Mark native encoding failures, keeping ordinary errors unchanged.
cn_encoding_call <- function(code, argument = "x") {
  tryCatch(code, error = function(error) {
    if (inherits(error, "cn_encoding_error")) stop(error)
    message <- conditionMessage(error)
    if (!grepl("UTF-8|bytes.*encoding|Unicode noncharacter|invalid multibyte|utf8towcs", message)) stop(error)
    stop(structure(list(message = message, call = NULL, argument = argument,
      original_message = message), class = c("cn_encoding_error", "simpleError", "error", "condition")))
  })
}

cn_with_encoding_context <- function(x, na, code) {
  force(x)
  force(na)
  tryCatch(cn_encoding_call(code), cn_encoding_error = function(error) {
    input <- if (error$argument == "na") na else x
    if (is.factor(input)) input <- as.character(input)
    # ponytail: binary-search only on failure; native validation stays the oracle
    # and successful batches do not acquire an extra encoding scan.
    lo <- 1L
    hi <- length(input)
    while (lo < hi) {
      middle <- floor((lo + hi) / 2)
      valid <- tryCatch({
        cn_encoding_call(.Call(C_normalize_characters, enc2utf8(input[seq.int(lo, middle)]), FALSE))
        TRUE
      }, cn_encoding_error = function(e) FALSE)
      if (valid) lo <- middle + 1L else hi <- middle
    }
    error$index <- lo
    error$message <- paste0(error$original_message, " Input `", error$argument,
                            "` at position ", lo, ".")
    stop(error)
  })
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
