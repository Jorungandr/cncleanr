#' Parse Compact Numbers Used in Chinese Data
#'
#' Converts character values such as `"1.25\u4e07"`, `"\uffe53\u4ebf"`,
#' `"1.2e5"`, and `"12.5%"`
#' to doubles. Parsing is deliberately conservative: every non-missing value
#' must match the supported syntax in full. Spaces between digits are accepted
#' only when they form valid three-digit grouping.
#'
#' @param x A character, factor, or numeric vector. When `unit = NULL`, numeric
#'   input is converted to double and otherwise passed through unchanged,
#'   including `Inf`, `-Inf`, and `NaN`.
#' @param na A character vector containing values that should be interpreted as
#'   missing. Matching happens after whitespace and full-width normalization.
#' @param strict A single logical value. If `FALSE`, invalid values become
#'   `NA_real_`, a warning is emitted, and a data frame is stored in the
#'   `problems` attribute. If `TRUE`, invalid values cause an error.
#' @param unit A single optional table-header unit: yuan, thousand yuan,
#'   ten thousand, hundred million, or trillion, optionally in yuan. Use the
#'   spellings `"\u5143"`, `"\u5343\u5143"`, `"\u4e07"`,
#'   `"\u4e07\u5143"`, `"\u4ebf"`, `"\u4ebf\u5143"`,
#'   `"\u4e07\u4ebf"`, or `"\u4e07\u4ebf\u5143"`.
#'   Bare values inherit this unit;
#'   explicit units must have the same multiplier and are not scaled twice.
#'   Percentages conflict with a header unit. With a header unit, numeric input
#'   follows character parsing: missing values remain missing, while infinities
#'   and overflow are reported as problems. Defaults to `NULL` (no header unit).
#'
#' @return A double vector with the same length and names as `x`. When invalid
#'   values occur in non-strict mode, the result has a `problems` attribute with
#'   columns `index`, `value`, and `reason`.
#'
#' @details Finite-range validation applies to parsed character and factor
#'   input. With `unit = NULL`, existing numeric `Inf`, `-Inf`, and `NaN`
#'   values are preserved.
#'
#' @usage
#' parse_cn_number(
#'   x,
#'   na = c(
#'     "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
#'     "\u2014", "\u2013", "-", "...", "\u2026"
#'   ),
#'   strict = FALSE,
#'   unit = NULL
#' )
#'
#' @examples
#' parse_cn_number(c("1.25\u4e07", "3\u4ebf\u5143", "12.5%", "\u6682\u65e0"))
#' parse_cn_number(c("\uff11\uff12\uff0e\uff15\uff05", "(2.5\u4e07)"))
#' parse_cn_number(c("123.5", "1.5\u5343\u5143"), unit = "\u5343\u5143")
#'
#' @export
parse_cn_number <- function(
  x,
  na = c(
    "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
    "\u2014", "\u2013", "-", "...", "\u2026"
  ),
  strict = FALSE,
  unit = NULL
) {
  if (!is.logical(strict) || length(strict) != 1L || is.na(strict)) {
    stop("`strict` must be a single TRUE or FALSE value.", call. = FALSE)
  }
  if (!is.character(na)) {
    stop("`na` must be a character vector.", call. = FALSE)
  }
  header_multipliers <- c(
    "\u5143" = 1, "\u5343\u5143" = 1e3,
    "\u4e07" = 1e4, "\u4e07\u5143" = 1e4,
    "\u4ebf" = 1e8, "\u4ebf\u5143" = 1e8,
    "\u4e07\u4ebf" = 1e12, "\u4e07\u4ebf\u5143" = 1e12
  )
  if (!is.null(unit) &&
      (!is.character(unit) || length(unit) != 1L || is.na(unit) ||
       !unit %in% names(header_multipliers))) {
    stop("`unit` must be NULL or a single supported Chinese header unit.", call. = FALSE)
  }
  header_multiplier <- if (is.null(unit)) NULL else unname(header_multipliers[[unit]])
  if (is.numeric(x)) {
    if (is.null(unit)) {
      output <- as.double(x)
      names(output) <- names(x)
      return(output)
    }
    input_names <- names(x)
    missing <- is.na(x)
    x <- sprintf("%.17g", x)
    x[missing] <- NA_character_
    names(x) <- input_names
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (!is.character(x)) {
    stop("`x` must be a character, factor, or numeric vector.", call. = FALSE)
  }
  if (length(x) == 0L) {
    return(numeric())
  }

  input_names <- names(x)
  original <- x
  invalid_spacing <- has_invalid_cn_digit_spacing(x)
  normalized <- normalize_cn_number_text(x)
  normalized_na <- normalize_cn_number_text(na)
  is_missing <- is.na(normalized) | normalized %in% normalized_na

  output <- rep(NA_real_, length(normalized))
  names(output) <- input_names
  active <- which(!is_missing)

  if (length(active) == 0L) {
    return(output)
  }

  work <- normalized[active]
  accounting <- grepl("^\\(.*\\)$", work, perl = TRUE)
  work[accounting] <- sub("^\\((.*)\\)$", "\\1", work[accounting], perl = TRUE)

  pattern <- paste0(
    "^([+-]?)",
    "(\u00a5|\u4eba\u6c11\u5e01|(?i:RMB|CNY))?",
    "([+-]?)",
    "((?:(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?)",
    "(\u4e07\u4ebf|\u4e07|\u4ebf|\u5343(?=\u5143))?",
    "(\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)?",
    "(%)?$"
  )
  matches <- regexpr(pattern, work, perl = TRUE)
  matched <- matches > 0L
  reasons <- rep("value does not match the supported number syntax", length(work))
  invalid_work_spacing <- invalid_spacing[active]
  matched[invalid_work_spacing] <- FALSE
  reasons[invalid_work_spacing] <- "digits use invalid whitespace grouping"

  starts <- attr(matches, "capture.start")
  ends <- starts + attr(matches, "capture.length") - 1L
  fields <- lapply(seq_len(7L), function(j) substring(work, starts[, j], ends[, j]))
  sign_before <- fields[[1L]]
  sign_after <- fields[[3L]]
  magnitude <- fields[[5L]]
  percent <- nzchar(fields[[7L]])
  explicit_unit <- nzchar(magnitude) | nzchar(fields[[2L]]) | nzchar(fields[[6L]])
  # Apply validations in their original order so the first error stays stable.
  reject <- function(condition, reason) {
    bad <- which(matched & condition)
    matched[bad] <<- FALSE
    reasons[bad] <<- reason
  }
  reject(nzchar(sign_before) & nzchar(sign_after),
         "a value cannot contain more than one explicit sign")
  reject(accounting & (nzchar(sign_before) | nzchar(sign_after)),
         "accounting parentheses cannot contain an explicit sign")
  reject(percent & explicit_unit,
         "percentages cannot also use currency or a magnitude suffix")
  value <- suppressWarnings(as.double(gsub(",", "", fields[[4L]], fixed = TRUE)))
  reject(!is.finite(value), "value is outside the finite double range")
  multiplier <- c(1, 1e4, 1e8, 1e12, 1e3)[
    match(magnitude, c("", "\u4e07", "\u4ebf", "\u4e07\u4ebf", "\u5343"), nomatch = 1L)
  ]
  if (!is.null(header_multiplier)) {
    reject(percent | (explicit_unit & multiplier != header_multiplier),
           "explicit unit conflicts with the table-header unit")
    multiplier[!explicit_unit] <- header_multiplier
  }
  value <- value * multiplier
  reject(!is.finite(value), "value is outside the finite double range")
  negative <- sign_before == "-" | sign_after == "-" | accounting
  value[negative] <- -value[negative]
  value[percent] <- value[percent] / 100
  output[active[matched]] <- value[matched]

  failed_local <- which(!matched)
  if (length(failed_local) > 0L) {
    failed <- active[failed_local]
    problems <- data.frame(
      index = failed,
      value = original[failed],
      reason = reasons[failed_local],
      stringsAsFactors = FALSE
    )
    message <- format_cn_parse_failure(problems)

    if (strict) {
      stop(message, call. = FALSE)
    }
    attr(output, "problems") <- problems
    warning(message, call. = FALSE)
  }

  output
}

normalize_cn_number_text <- function(x) {
  x <- normalize_cn_number_characters(x)
  gsub("[[:space:]\u3000\u00a0\u202f]+", "", x, perl = TRUE)
}

normalize_cn_number_characters <- function(x) {
  x <- enc2utf8(x)
  x <- chartr(
    "\uff0d\uff10\uff11\uff12\uff13\uff14\uff15\uff16\uff17\uff18\uff19\uff0e\uff0c\uff05\uff0b\uff08\uff09\uffe5\uff1c\uff1e\uff1d\uff25\uff45",
    "-0123456789.,%+()\u00a5<>=Ee",
    x
  )
  gsub("[\u2212\ufe63\u2013]", "-", x, perl = TRUE)
}

has_invalid_cn_digit_spacing <- function(x) {
  x <- normalize_cn_number_characters(x)
  spacing <- "[[:space:]\u3000\u00a0\u202f]"
  has_digit_spacing <- grepl(
    paste0("[0-9]", spacing, "+[0-9]"),
    x,
    perl = TRUE
  )
  valid_grouping <- grepl(
    paste0(
      "^[^0-9]*",
      "[0-9]{1,3}(?:", spacing, "+[0-9]{3})+",
      "(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?",
      "[^0-9]*$"
    ),
    x,
    perl = TRUE
  )
  has_digit_spacing & !valid_grouping
}

format_cn_parse_failure <- function(problems) {
  count <- nrow(problems)
  positions <- paste(utils::head(problems$index, 5L), collapse = ", ")
  if (count > 5L) {
    positions <- paste0(positions, ", ...")
  }
  summary <- sprintf(
    "Failed to parse %d value%s at positions %s.",
    count,
    if (count == 1L) "" else "s",
    positions
  )
  first_reason <- sub("[.]$", "", problems$reason[[1L]])
  paste0(summary, " First problem: ", first_reason, ".")
}
