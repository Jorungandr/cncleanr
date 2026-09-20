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
#' @usage
#' parse_cn_range(
#'   x,
#'   na = c(
#'     "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
#'     "\u2014", "\u2013", "-", "...", "\u2026"
#'   ),
#'   strict = FALSE
#' )
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
  invalid_spacing <- has_invalid_cn_digit_spacing(x)
  normalized <- normalize_cn_number_text(x)
  normalized_na <- normalize_cn_number_text(na)
  is_missing <- is.na(normalized) | normalized %in% normalized_na
  invalid_spacing <- invalid_spacing & !is_missing
  problem_reason <- rep(NA_character_, size)
  problem_reason[invalid_spacing] <- "digits use invalid whitespace grouping"
  active <- which(!is_missing & !invalid_spacing)

  if (length(active) > 0L) {
    unique_text <- unique(normalized[active])
    active_map <- match(normalized[active], unique_text)
    unique_output <- output[seq_along(unique_text), , drop = FALSE]
    unique_reason <- rep(NA_character_, length(unique_text))
    quantity <- suppressWarnings(parse_cn_quantity(unique_text, na = normalized_na))
    quantity_failed <- cn_problems(quantity)$index
    quantity_ok <- setdiff(seq_along(unique_text), quantity_failed)

    for (i in quantity_ok) {
      value <- quantity$value[[i]]
      qualifier <- quantity$qualifier[[i]]
      if (identical(qualifier, "approx")) {
        unique_reason[[i]] <- "an approximate value does not define explicit bounds"
      } else if (identical(qualifier, "exact")) {
        unique_output[i, ] <- list(value, value, TRUE, TRUE)
      } else if (identical(qualifier, "at_least")) {
        unique_output[i, ] <- list(value, Inf, TRUE, FALSE)
      } else if (identical(qualifier, "greater_than")) {
        unique_output[i, ] <- list(value, Inf, FALSE, FALSE)
      } else if (identical(qualifier, "at_most")) {
        unique_output[i, ] <- list(-Inf, value, FALSE, TRUE)
      } else if (identical(qualifier, "less_than")) {
        unique_output[i, ] <- list(-Inf, value, FALSE, FALSE)
      }
    }

    if (length(quantity_failed) > 0L) {
      ranges <- find_cn_range_endpoints_batch(
        unique_text[quantity_failed],
        normalized_na
      )
      for (j in seq_along(quantity_failed)) {
        i <- quantity_failed[[j]]
        values <- ranges$values[[j]]
        if (is.null(values)) {
          unique_reason[[i]] <- ranges$reason[[j]]
        } else if (values[[1L]] > values[[2L]]) {
          unique_reason[[i]] <-
            "range lower bound is greater than its upper bound"
        } else {
          unique_output[i, ] <- list(values[[1L]], values[[2L]], TRUE, TRUE)
        }
      }
    }

    output[active, ] <- unique_output[active_map, , drop = FALSE]
    problem_reason[active] <- unique_reason[active_map]
  }

  failed <- which(!is.na(problem_reason))
  problems <- data.frame(
    index = failed,
    value = original[failed],
    reason = problem_reason[failed],
    stringsAsFactors = FALSE
  )
  apply_cn_problems(output, problems, strict)
}

find_cn_range_endpoints_batch <- function(text, na) {
  size <- length(text)
  values <- vector("list", size)
  reason <- rep("one or both range endpoints are invalid", size)
  candidate_source <- integer()
  candidate_left <- character()
  candidate_right <- character()

  for (i in seq_along(text)) {
    positions <- gregexpr(
      "[\u81f3\u5230~\uff5e\u2014\u2013-]",
      text[[i]],
      perl = TRUE
    )[[1L]]
    if (identical(positions[[1L]], -1L)) {
      reason[[i]] <- "value is not a supported range or bound"
      next
    }

    for (position in positions) {
      left <- substr(text[[i]], 1L, position - 1L)
      right <- substr(text[[i]], position + 1L, nchar(text[[i]]))
      if (!nzchar(left) || !nzchar(right)) {
        next
      }
      endpoints <- propagate_cn_range_suffix(c(left, right))
      candidate_source <- c(candidate_source, i)
      candidate_left <- c(candidate_left, endpoints[[1L]])
      candidate_right <- c(candidate_right, endpoints[[2L]])
    }
  }

  if (length(candidate_source) == 0L) {
    return(list(values = values, reason = reason))
  }

  endpoint_text <- as.vector(rbind(candidate_left, candidate_right))
  parsed <- suppressWarnings(parse_cn_number(endpoint_text, na = na))
  invalid_endpoint <- rep(FALSE, length(parsed))
  invalid_endpoint[cn_problems(parsed)$index] <- TRUE
  invalid_endpoint[is.na(parsed)] <- TRUE
  candidate_valid <-
    !invalid_endpoint[seq.int(1L, length(parsed), by = 2L)] &
    !invalid_endpoint[seq.int(2L, length(parsed), by = 2L)]
  parsed <- matrix(as.numeric(parsed), ncol = 2L, byrow = TRUE)

  for (i in seq_along(text)) {
    matches <- which(candidate_source == i & candidate_valid)
    if (length(matches) == 1L) {
      values[[i]] <- parsed[matches, ]
      reason[[i]] <- NA_character_
    } else if (length(matches) > 1L) {
      reason[[i]] <- "range contains more than one valid separator"
    }
  }

  list(values = values, reason = reason)
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
