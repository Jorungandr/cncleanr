#' Parse Numeric Ranges Used in Chinese Data
#'
#' Converts closed ranges such as `"3\u4e07-5\u4e07"` and open bounds such as
#' `"10\u4e07\u5143\u4ee5\u4e0a"` into explicit lower and upper bounds. A shared suffix in
#' `"3-5\u4e07"` is applied to both endpoints. Signs used by negative numbers and
#' scientific notation are distinguished from range separators.
#'
#' @inheritParams parse_cn_number
#'
#' @return A data frame with columns `lower`, `upper`, `lower_inclusive`, and
#'   `upper_inclusive`. Numeric input becomes an inclusive point range,
#'   including numeric `Inf` and `-Inf`; `NA` and `NaN` have missing
#'   inclusivity. Infinite bounds created from textual inequalities represent
#'   open-ended bounds and are distinct from numeric point inputs.
#'
#' @examples
#' parse_cn_range(c("3\u4e07-5\u4e07", "3-5\u4e07", "10\u4e07\u5143\u4ee5\u4e0a"))
#'
#' @export
parse_cn_range <- function(
  x,
  na = c(
    "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
    "\u2014", "\u2013", "-", "...", "\u2026"
  ),
  strict = FALSE
) {
  validate_cn_parse_arguments(x, na, strict)

  if (is.numeric(x)) {
    value <- as.double(x)
    present <- !is.na(value)
    return(data.frame(
      lower = value,
      upper = value,
      lower_inclusive = ifelse(present, TRUE, NA),
      upper_inclusive = ifelse(present, TRUE, NA)
    ))
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }

  size <- length(x)
  output <- data.frame(
    lower = rep(NA_real_, size),
    upper = rep(NA_real_, size),
    lower_inclusive = rep(NA, size),
    upper_inclusive = rep(NA, size)
  )
  if (size == 0L) {
    return(output)
  }

  original <- x
  normalized <- normalize_cn_number_text(x)
  normalized_na <- normalize_cn_number_text(na)
  is_missing <- is.na(normalized) | normalized %in% normalized_na
  problems <- empty_cn_problems()
  for (i in which(!is_missing)) {
    quantity <- suppressWarnings(parse_cn_quantity(normalized[[i]], na = normalized_na))
    quantity_problems <- cn_problems(quantity)
    if (nrow(quantity_problems) == 0L) {
      if (identical(quantity$qualifier[[1L]], "approx")) {
        problems <- rbind(problems, data.frame(
          index = i,
          value = original[[i]],
          reason = "an approximate value does not define explicit bounds",
          stringsAsFactors = FALSE
        ))
        next
      }

      value <- quantity$value[[1L]]
      qualifier <- quantity$qualifier[[1L]]
      if (identical(qualifier, "exact")) {
        output[i, ] <- list(value, value, TRUE, TRUE)
      } else if (identical(qualifier, "at_least")) {
        output[i, ] <- list(value, Inf, TRUE, FALSE)
      } else if (identical(qualifier, "greater_than")) {
        output[i, ] <- list(value, Inf, FALSE, FALSE)
      } else if (identical(qualifier, "at_most")) {
        output[i, ] <- list(-Inf, value, FALSE, TRUE)
      } else if (identical(qualifier, "less_than")) {
        output[i, ] <- list(-Inf, value, FALSE, FALSE)
      }
      next
    }

    range <- find_cn_range_endpoints(normalized[[i]], normalized_na)
    if (is.null(range$values)) {
      problems <- rbind(problems, data.frame(
        index = i,
        value = original[[i]],
        reason = range$reason,
        stringsAsFactors = FALSE
      ))
      next
    }

    if (range$values[[1L]] > range$values[[2L]]) {
      problems <- rbind(problems, data.frame(
        index = i,
        value = original[[i]],
        reason = "range lower bound is greater than its upper bound",
        stringsAsFactors = FALSE
      ))
      next
    }

    output$lower[[i]] <- range$values[[1L]]
    output$upper[[i]] <- range$values[[2L]]
    output$lower_inclusive[[i]] <- TRUE
    output$upper_inclusive[[i]] <- TRUE
  }

  apply_cn_problems(output, problems, strict)
}

find_cn_range_endpoints <- function(text, na) {
  positions <- gregexpr("[\u81f3\u5230~\uff5e\u2014\u2013-]", text, perl = TRUE)[[1L]]
  if (identical(positions[[1L]], -1L)) {
    return(list(
      values = NULL,
      reason = "value is not a supported range or bound"
    ))
  }

  candidates <- list()
  for (position in positions) {
    left <- substr(text, 1L, position - 1L)
    right <- substr(text, position + 1L, nchar(text))
    if (!nzchar(left) || !nzchar(right)) {
      next
    }

    endpoints <- propagate_cn_range_suffix(c(left, right))
    parsed <- suppressWarnings(parse_cn_number(endpoints, na = na))
    if (nrow(cn_problems(parsed)) == 0L) {
      candidates[[length(candidates) + 1L]] <- as.numeric(parsed)
    }
  }

  if (length(candidates) == 1L) {
    return(list(values = candidates[[1L]], reason = NULL))
  }
  if (length(candidates) > 1L) {
    return(list(
      values = NULL,
      reason = "range contains more than one valid separator"
    ))
  }

  list(
    values = NULL,
    reason = "one or both range endpoints are invalid"
  )
}

propagate_cn_range_suffix <- function(endpoints) {
  suffix_pattern <- paste0(
    "((?:\u4e07\u4ebf|\u4e07|\u4ebf)(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)?|",
    "(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)|%)$"
  )
  suffixes <- vapply(endpoints, function(value) {
    match <- regmatches(value, regexpr(suffix_pattern, value, perl = TRUE))
    if (length(match) == 0L || identical(match, character(0))) "" else match
  }, character(1), USE.NAMES = FALSE)

  if (!nzchar(suffixes[[1L]]) && nzchar(suffixes[[2L]])) {
    endpoints[[1L]] <- paste0(endpoints[[1L]], suffixes[[2L]])
  } else if (nzchar(suffixes[[1L]]) && !nzchar(suffixes[[2L]])) {
    endpoints[[2L]] <- paste0(endpoints[[2L]], suffixes[[1L]])
  }
  endpoints
}
