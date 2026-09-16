#' Parse Numeric Ranges Used in Chinese Data
#'
#' Converts closed ranges such as `"3\u4e07-5\u4e07"` and open bounds such as
#' `"10\u4e07\u5143\u4ee5\u4e0a"` into explicit lower and upper bounds. A shared suffix in
#' `"3-5\u4e07"` is applied to both endpoints.
#'
#' @inheritParams parse_cn_number
#'
#' @return A data frame with columns `lower`, `upper`, `lower_inclusive`, and
#'   `upper_inclusive`. Infinite bounds are represented by `-Inf` or `Inf`.
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
  range_pattern <- "^(.+?)(?:\u81f3|\u5230|~|\uff5e|\u2014|\u2013|-)(.+)$"

  for (i in which(!is_missing)) {
    fields <- regmatches(normalized[[i]], regexec(range_pattern, normalized[[i]], perl = TRUE))[[1L]]

    if (length(fields) > 0L) {
      endpoints <- propagate_cn_range_suffix(fields[2:3])
      parsed <- suppressWarnings(parse_cn_number(endpoints, na = normalized_na))
      endpoint_problems <- cn_problems(parsed)
      if (nrow(endpoint_problems) > 0L) {
        problems <- rbind(problems, data.frame(
          index = i,
          value = original[[i]],
          reason = "one or both range endpoints are invalid",
          stringsAsFactors = FALSE
        ))
        next
      }
      if (parsed[[1L]] > parsed[[2L]]) {
        problems <- rbind(problems, data.frame(
          index = i,
          value = original[[i]],
          reason = "range lower bound is greater than its upper bound",
          stringsAsFactors = FALSE
        ))
        next
      }

      output$lower[[i]] <- parsed[[1L]]
      output$upper[[i]] <- parsed[[2L]]
      output$lower_inclusive[[i]] <- TRUE
      output$upper_inclusive[[i]] <- TRUE
      next
    }

    quantity <- suppressWarnings(parse_cn_quantity(normalized[[i]], na = normalized_na))
    quantity_problems <- cn_problems(quantity)
    if (nrow(quantity_problems) > 0L || identical(quantity$qualifier[[1L]], "approx")) {
      reason <- if (nrow(quantity_problems) > 0L) {
        "value is not a supported range or bound"
      } else {
        "an approximate value does not define explicit bounds"
      }
      problems <- rbind(problems, data.frame(
        index = i,
        value = original[[i]],
        reason = reason,
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
  }

  apply_cn_problems(output, problems, strict)
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
