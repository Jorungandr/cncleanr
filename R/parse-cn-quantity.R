#' Parse Qualified Quantities Used in Chinese Data
#'
#' Parses exact values and values qualified by language or symbols, such as
#' `"\u7ea63\u4e07"`, `"\u5927\u4e8e2\u4ebf"`, `"\u4e0d\u5c0f\u4e8e5\u4e07"`, `"10\u4e07+"`, `"50\u4f59"`, or
#' `"50\u4f59\u4e07\u5143"`.
#' The qualifier is retained instead of silently discarded.
#'
#' @inheritParams parse_cn_number
#'
#' @return A data frame with double column `value` and character column
#'   `qualifier`. Qualifiers are `exact`, `approx`, `greater_than`, `at_least`,
#'   `less_than`, and `at_most`. Numeric finite and infinite values have the
#'   qualifier `exact`; `NA` and `NaN` have a missing qualifier. Numeric values,
#'   including `Inf`, `-Inf`, and `NaN`, are preserved in `value`.
#'
#' @usage
#' parse_cn_quantity(
#'   x,
#'   na = c(
#'     "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
#'     "\u2014", "\u2013", "-", "...", "\u2026"
#'   ),
#'   strict = FALSE
#' )
#'
#' @examples
#' parse_cn_quantity(c(
#'   "\u7ea63\u4e07", "\u5927\u4e8e2\u4ebf", "10\u4e07+", "50\u4f59", "50\u4f59\u4e07\u5143"
#' ))
#'
#' @export
parse_cn_quantity <- function(
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
    qualifier <- rep("exact", length(value))
    qualifier[is.na(value)] <- NA_character_
    return(data.frame(value = value, qualifier = qualifier))
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (length(x) == 0L) {
    return(data.frame(value = numeric(), qualifier = character()))
  }

  original <- x
  invalid_spacing <- has_invalid_cn_digit_spacing(x)
  cleaned <- normalize_cn_number_text(x)
  normalized_na <- normalize_cn_number_text(na)
  is_missing <- is.na(cleaned) | cleaned %in% normalized_na
  qualifier <- rep("exact", length(cleaned))
  qualifier[is_missing] <- NA_character_
  conflict <- rep(FALSE, length(cleaned))

  prefix_rules <- c(
    at_most = "^(?:\u4e0d\u8d85\u8fc7|\u4e0d\u9ad8\u4e8e|\u4e0d\u5927\u4e8e|\u4e0d\u591a\u4e8e|\u81f3\u591a|<=|\u2264|\u2266)",
    at_least = "^(?:\u4e0d\u5c11\u4e8e|\u4e0d\u4f4e\u4e8e|\u4e0d\u5c0f\u4e8e|\u81f3\u5c11|>=|\u2265|\u2267)",
    greater_than = "^(?:\u8d85\u8fc7|\u8d85\u51fa|\u5927\u4e8e|\u9ad8\u4e8e|\u591a\u4e8e|>(?!=))",
    less_than = "^(?:\u4f4e\u4e8e|\u5c0f\u4e8e|\u4e0d\u8db3|\u5c11\u4e8e|<(?!=))",
    approx = "^(?:\u5927\u7ea6|\u7ea6\u4e3a|\u5927\u6982|\u7ea6|\u8fd1)"
  )
  suffix_rules <- c(
    at_least = "(?:\u4ee5\u4e0a|\\+)$",
    at_most = "\u4ee5\u4e0b$",
    greater_than = "\u4f59$",
    approx = "\u5de6\u53f3$"
  )

  for (i in which(!is_missing)) {
    prefix_hits <- names(prefix_rules)[vapply(
      prefix_rules,
      function(pattern) grepl(pattern, cleaned[[i]], perl = TRUE),
      logical(1)
    )]
    suffix_hits <- names(suffix_rules)[vapply(
      suffix_rules,
      function(pattern) grepl(pattern, cleaned[[i]], perl = TRUE),
      logical(1)
    )]
    infix_pattern <- paste0(
      "^(.+)\u4f59(",
      "(?:\u4e07\u4ebf|\u4e07|\u4ebf)(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)?|",
      "(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)",
      ")$"
    )
    infix_fields <- regmatches(
      cleaned[[i]],
      regexec(infix_pattern, cleaned[[i]], perl = TRUE)
    )[[1L]]
    has_infix_yu <- length(infix_fields) > 0L

    if (length(prefix_hits) + length(suffix_hits) + has_infix_yu > 1L) {
      conflict[[i]] <- TRUE
      qualifier[[i]] <- NA_character_
      next
    }
    if (length(prefix_hits) == 1L) {
      qualifier[[i]] <- prefix_hits
      cleaned[[i]] <- sub(prefix_rules[[prefix_hits]], "", cleaned[[i]], perl = TRUE)
    } else if (length(suffix_hits) == 1L) {
      qualifier[[i]] <- suffix_hits
      cleaned[[i]] <- sub(suffix_rules[[suffix_hits]], "", cleaned[[i]], perl = TRUE)
    } else if (has_infix_yu) {
      qualifier[[i]] <- "greater_than"
      cleaned[[i]] <- paste0(infix_fields[[2L]], infix_fields[[3L]])
    }
  }

  invalid_spacing <- invalid_spacing & !is_missing & !conflict
  cleaned[conflict | invalid_spacing] <- NA_character_
  parsed <- suppressWarnings(parse_cn_number(cleaned, na = normalized_na))
  problems <- cn_problems(parsed)
  if (nrow(problems) > 0L) {
    problems$value <- original[problems$index]
  }
  if (any(conflict)) {
    conflict_problems <- data.frame(
      index = which(conflict),
      value = original[conflict],
      reason = "multiple or conflicting qualifiers",
      stringsAsFactors = FALSE
    )
    problems <- rbind(problems, conflict_problems)
  }
  if (any(invalid_spacing)) {
    spacing_problems <- data.frame(
      index = which(invalid_spacing),
      value = original[invalid_spacing],
      reason = "digits use invalid whitespace grouping",
      stringsAsFactors = FALSE
    )
    problems <- rbind(problems, spacing_problems)
  }

  value <- as.numeric(parsed)
  value[conflict | invalid_spacing] <- NA_real_
  if (nrow(problems) > 0L) {
    qualifier[unique(problems$index)] <- NA_character_
  }
  output <- data.frame(value = value, qualifier = qualifier)
  apply_cn_problems(output, problems, strict)
}

validate_cn_parse_arguments <- function(x, na, strict) {
  if (!is.logical(strict) || length(strict) != 1L || is.na(strict)) {
    stop("`strict` must be a single TRUE or FALSE value.", call. = FALSE)
  }
  if (!is.character(na)) {
    stop("`na` must be a character vector.", call. = FALSE)
  }
  if (!is.numeric(x) && !is.factor(x) && !is.character(x)) {
    stop("`x` must be a character, factor, or numeric vector.", call. = FALSE)
  }
  invisible(NULL)
}
