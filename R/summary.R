#' Summarize Parsing Outcomes and Failure Reasons
#'
#' Counts successful, missing and failed rows without reparsing source data.
#'
#' @param x An unmodified result from a cncleanr parser or [cn_subset()].
#' @return A list with two ordinary data frames. `counts` has one row with
#'   columns `total`, `parsed`, `missing`, `failed`. `reasons` has columns
#'   `reason` and `count`, in first-occurrence order. Empty results have zero
#'   counts and a zero-row reason table. Repeated selections count repeatedly.
#' @details NA and NaN rows count as missing unless their positions occur in
#'   the attached problems table, in which case they count as failed. Numeric
#'   infinities and textual open range bounds are valid parsed values.
#'   Obvious malformed results or stale problem indices cause an error.
#'   Quantity qualifiers must agree with missingness, and range bounds and
#'   inclusivity must be internally consistent. Plain R results do not prove
#'   provenance: diagnostics removed or made stale by other
#'   transformations cannot always be detected or recovered. Summarize before
#'   ordinary subsetting, mutation, binding or CSV export, or use [cn_subset()].
#'   Only this explicit summary scans result values; existing parsers do no extra
#'   summary work. No parsing warnings are repeated and `x` is not modified.
#' @examples
#' result <- suppressWarnings(parse_cn_number(c("3\u4e07", "bad", "\u6682\u65e0")))
#' cn_summary(result)
#' cn_summary(cn_subset(result, c(2, 1, 2)))
#' @export
cn_summary <- function(x) {
  problems <- cn_result_problems(x)
  frame <- is.data.frame(x)
  primary <- if (frame) x[[1L]] else x
  numeric_vector <- function(value)
    is.numeric(value) && !is.complex(value) && !is.object(value) && is.null(dim(value))
  if (!numeric_vector(primary) ||
      (frame && length(x) == 2L && !is.character(x$qualifier)) ||
      (frame && length(x) == 4L && (!numeric_vector(x$upper) ||
        !is.logical(x$lower_inclusive) || !is.logical(x$upper_inclusive) ||
        any(is.na(primary) != is.na(x$upper)))))
    stop("`x` must be an unmodified cncleanr result with valid columns.", call. = FALSE)
  absent <- is.na(primary)
  if (frame && length(x) == 2L &&
      (!is.null(dim(x$qualifier)) || any(is.na(x$qualifier) != absent) ||
       any(!is.na(x$qualifier) & !x$qualifier %in%
         c("exact", "approx", "greater_than", "at_least", "less_than", "at_most"))))
    stop("`x` must be an unmodified cncleanr result with valid qualifiers.", call. = FALSE)
  if (frame && length(x) == 4L &&
      (!is.null(dim(x$lower_inclusive)) || !is.null(dim(x$upper_inclusive)) ||
       any(absent & (!is.na(x$lower_inclusive) | !is.na(x$upper_inclusive))) ||
       any(!absent & (is.na(x$lower_inclusive) | is.na(x$upper_inclusive))) ||
       any(!absent & (primary > x$upper |
         (primary == x$upper & !(x$lower_inclusive & x$upper_inclusive))), na.rm = TRUE)))
    stop("`x` must be an unmodified cncleanr result with valid bounds and inclusivity.", call. = FALSE)
  if (!is.character(problems$value) || !is.character(problems$reason) ||
      !is.null(dim(problems$value)) || !is.null(dim(problems$reason)) ||
      anyNA(problems$reason) || any(!nzchar(problems$reason)) ||
      is.object(problems$index) || !is.null(dim(problems$index)) ||
      any(!absent[problems$index]))
    stop("`x` has invalid or stale problems; use the original parser result.", call. = FALSE)
  total <- length(primary)
  failed <- nrow(problems)
  absent_count <- sum(absent)
  reason <- unique(problems$reason)
  list(counts = data.frame(total = total, parsed = total - absent_count,
                          missing = absent_count - failed, failed = failed),
       reasons = data.frame(reason = reason,
         count = tabulate(match(problems$reason, reason), nbins = length(reason)),
         stringsAsFactors = FALSE))
}
