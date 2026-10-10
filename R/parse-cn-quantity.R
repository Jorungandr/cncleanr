#' Parse Qualified Quantities Used in Chinese Data
#'
#' Parses exact values and values qualified by language or symbols, such as
#' `"\u7ea63\u4e07"`, `"\u5927\u4e8e2\u4ebf"`, `"\u4e0d\u5c0f\u4e8e5\u4e07"`, `"10\u4e07+"`, `"50\u4f59"`, or
#' `"50\u4f59\u4e07\u5143"`.
#' The qualifier is retained instead of silently discarded.
#' One approximation prefix combined with an approximation suffix is accepted,
#' for example `"\u7ea615%\u5de6\u53f3"`. Repeated prefixes or suffixes and
#' mixed inequality qualifiers are rejected.
#'
#' @inheritParams parse_cn_number
#' @param x A character, factor, or numeric vector. Numeric input is converted
#'   to double and otherwise passed through unchanged, including `Inf`, `-Inf`,
#'   and `NaN`.
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

  full_original <- x
  x <- unique(x)
  input_map <- match(full_original, x)
  original <- x
  characters <- normalize_cn_number_characters(x)
  invalid_spacing <- has_invalid_cn_digit_spacing(characters, characters_normalized = TRUE)
  cleaned <- normalize_cn_number_text(characters, characters_normalized = TRUE)
  normalized_na <- normalize_cn_number_text(na)
  is_missing <- is.na(cleaned) | cleaned %in% normalized_na
  qualifier <- rep("exact", length(cleaned))
  qualifier[is_missing] <- NA_character_

  prefix_rules <- c(
    at_most = "^(?:\u4e0d\u8d85\u8fc7|\u4e0d\u9ad8\u4e8e|\u4e0d\u5927\u4e8e|\u4e0d\u591a\u4e8e|\u81f3\u591a|<=|\u2264|\u2266)",
    at_least = "^(?:\u4e0d\u5c11\u4e8e|\u4e0d\u4f4e\u4e8e|\u4e0d\u5c0f\u4e8e|\u81f3\u5c11|>=|\u2265|\u2267)",
    greater_than = "^(?:\u8d85\u8fc7|\u8d85\u51fa|\u8d85|\u5927\u4e8e|\u9ad8\u4e8e|\u591a\u4e8e|>(?!=))",
    less_than = "^(?:\u4f4e\u4e8e|\u5c0f\u4e8e|\u4e0d\u8db3|\u5c11\u4e8e|<(?!=))",
    approx = "^(?:\u5927\u7ea6|\u7ea6\u4e3a|\u5927\u6982|\u7ea6|\u8fd1)"
  )
  suffix_rules <- c(
    at_least = "(?:\u4ee5\u4e0a|\\+)$",
    at_most = "\u4ee5\u4e0b$",
    greater_than = "\u4f59$",
    approx = "\u5de6\u53f3$"
  )

  active <- which(!is_missing)
  prefix_kind <- suffix_kind <- rep("", length(cleaned))
  prefix_count <- suffix_count <- integer(length(cleaned))
  prefix_length <- suffix_length <- integer(length(cleaned))
  # Each rule group is disjoint (e.g. > excludes >=). Capture its kind once,
  # then reuse match lengths for stripping instead of running each rule again.
  prefix_match <- regexpr(paste0("(", prefix_rules, ")", collapse = "|"),
                         cleaned[active], perl = TRUE)
  hits <- which(prefix_match > 0L)
  prefix_kind[active[hits]] <- names(prefix_rules)[max.col(
    attr(prefix_match, "capture.start")[hits, , drop = FALSE], ties.method = "first")]
  prefix_count[active[hits]] <- 1L
  prefix_length[active[hits]] <- attr(prefix_match, "match.length")[hits]
  suffix_match <- regexpr(paste0("(", suffix_rules, ")", collapse = "|"),
                         cleaned[active], perl = TRUE)
  hits <- which(suffix_match > 0L)
  suffix_kind[active[hits]] <- names(suffix_rules)[max.col(
    attr(suffix_match, "capture.start")[hits, , drop = FALSE], ties.method = "first")]
  suffix_count[active[hits]] <- 1L
  suffix_length[active[hits]] <- attr(suffix_match, "match.length")[hits]
  infix_pattern <- paste0(
    "^(.+)\u4f59(",
    "(?:\u4e07\u4ebf|\u4e07|\u4ebf)(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)?|\u5343\u5143|",
    "(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)",
    ")$"
  )
  has_infix_yu <- rep(FALSE, length(cleaned))
  has_infix_yu[active] <- grepl(infix_pattern, cleaned[active], perl = TRUE)
  redundant_approx <- prefix_count == 1L & suffix_count == 1L &
    prefix_kind == "approx" & suffix_kind == "approx" & !has_infix_yu
  conflict <- prefix_count + suffix_count + has_infix_yu > 1L & !redundant_approx
  qualifier[conflict] <- NA_character_
  rows <- which(!conflict & prefix_count == 1L)
  qualifier[rows] <- prefix_kind[rows]
  cleaned[rows] <- substring(cleaned[rows], prefix_length[rows] + 1L)
  rows <- which(!conflict & prefix_count == 0L & suffix_count == 1L)
  qualifier[rows] <- suffix_kind[rows]
  rows <- c(rows, which(redundant_approx))
  cleaned[rows] <- substr(cleaned[rows], 1L, nchar(cleaned[rows]) - suffix_length[rows])
  rows <- which(!conflict & prefix_count == 0L & suffix_count == 0L & has_infix_yu)
  qualifier[rows] <- "greater_than"
  cleaned[rows] <- sub(infix_pattern, "\\1\\2", cleaned[rows], perl = TRUE)

  invalid_spacing <- invalid_spacing & !is_missing & !conflict
  cleaned[is_missing | conflict | invalid_spacing] <- NA_character_
  parsed <- suppressWarnings(parse_cn_number(cleaned, na = character()))
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
  reason <- rep(NA_character_, length(x))
  reason[problems$index] <- problems$reason
  failed <- which(!is.na(reason[input_map]))
  problems <- data.frame(index = failed, value = full_original[failed],
                         reason = reason[input_map[failed]], stringsAsFactors = FALSE)
  output <- data.frame(value = value[input_map], qualifier = qualifier[input_map])
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
