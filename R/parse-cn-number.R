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
#' Results use double precision, not exact integer or decimal arithmetic.
#' Nonzero character values rounded to zero after final unit conversion are
#' reported as underflow; representable subnormal values are retained.
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
#' @useDynLib cncleanr, .registration = TRUE, .fixes = "C_"
parse_cn_number <- function(
  x,
  na = c(
    "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
    "\u2014", "\u2013", "-", "...", "\u2026"
  ),
  strict = FALSE,
  unit = NULL
) {
  cn_with_encoding_context(x, na, {
  input_names <- names(x)
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
    missing <- is.na(x)
    x <- sprintf("%.17g", x)
    x[missing] <- NA_character_
    names(x) <- input_names
  }
  if (is.factor(x)) {
    x <- as.character(x)
    names(x) <- input_names
  }
  if (!is.character(x)) {
    stop("`x` must be a character, factor, or numeric vector.", call. = FALSE)
  }
  if (length(x) == 0L) {
    output <- numeric()
    names(output) <- input_names
    return(output)
  }

  fast <- cn_encoding_call(.Call(C_simple_numbers, x,
                if (is.null(header_multiplier)) NA_real_ else header_multiplier))
  normalized_na <- normalize_cn_number_text(na, argument = "na")
  missing_fast <- is.na(x) | x %in% normalized_na
  fast[missing_fast] <- NA_real_
  if (all(!is.na(fast) | missing_fast)) {
    names(fast) <- input_names
    return(fast)
  }
  original <- x
  pending <- which(is.na(fast) & !missing_fast)
  x <- x[pending]
  # ponytail: deduplicate only large fallback batches with substantial repetition.
  if (length(x) >= 1000L && anyDuplicated(x[seq_len(256L)])) {
    unique_text <- unique(x)
    if (length(unique_text) < length(x) / 2) {
      mapping <- match(x, unique_text)
      parsed <- suppressWarnings(parse_cn_number(unique_text, na = na, unit = unit))
      output <- fast
      output[pending] <- as.numeric(parsed)[mapping]
      names(output) <- input_names
      unique_problems <- attr(parsed, "problems")
      if (!is.null(unique_problems)) {
        problem_map <- match(mapping, unique_problems$index)
        failed <- which(!is.na(problem_map))
        problems <- data.frame(index = pending[failed], value = original[pending[failed]],
          reason = unique_problems$reason[problem_map[failed]], stringsAsFactors = FALSE)
        message <- format_cn_parse_failure(problems)
        if (strict) stop(message, call. = FALSE)
        attr(output, "problems") <- problems
        warning(message, call. = FALSE)
      }
      return(output)
    }
  }
  characters <- normalize_cn_number_characters(x)
  invalid_spacing <- has_invalid_cn_digit_spacing(characters, characters_normalized = TRUE)
  normalized <- normalize_cn_number_text(characters)
  is_missing <- is.na(normalized) | normalized %in% normalized_na

  output <- fast
  names(output) <- input_names
  normalized_fast <- rep(NA_real_, length(normalized))
  retry <- which(!is_missing & !invalid_spacing & normalized != x)
  if (length(retry)) {
    normalized_fast[retry] <- cn_encoding_call(.Call(C_simple_numbers, normalized[retry],
      if (is.null(header_multiplier)) NA_real_ else header_multiplier))
  }
  output[pending] <- normalized_fast
  active_local <- which(!is_missing & is.na(normalized_fast))
  active <- pending[active_local]

  if (length(active) == 0L) {
    return(output)
  }

  work <- normalized[active_local]
  invalid_work_spacing <- invalid_spacing[active_local]
  spacing_failed <- active[invalid_work_spacing]
  active <- active[!invalid_work_spacing]
  work <- work[!invalid_work_spacing]
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
  syntax_failed <- active[!matched]
  active <- active[matched]
  work <- work[matched]
  accounting <- accounting[matched]
  reasons <- rep("value does not match the supported number syntax", length(work))

  starts <- if (length(matches)) attr(matches, "capture.start")[matched, , drop = FALSE] else matrix(integer(), 0L, 7L)
  ends <- if (length(matches)) starts + attr(matches, "capture.length")[matched, , drop = FALSE] - 1L else starts
  matched <- rep(TRUE, length(work))
  fields <- if (length(work)) {
    lapply(seq_len(7L), function(j) substring(work, starts[, j], ends[, j]))
  } else rep(list(character()), 7L)
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
  number_text <- gsub(",", "", fields[[4L]], fixed = TRUE)
  value <- suppressWarnings(as.double(number_text))
  body_nonfinite <- !is.finite(value)
  multiplier <- c(1, 1e4, 1e8, 1e12, 1e3)[
    match(magnitude, c("", "\u4e07", "\u4ebf", "\u4e07\u4ebf", "\u5343"), nomatch = 1L)
  ]
  header_conflict <- rep(FALSE, length(value))
  if (!is.null(header_multiplier)) {
    header_conflict <- percent | (explicit_unit & multiplier != header_multiplier)
    multiplier[!explicit_unit] <- header_multiplier
  }
  scale <- multiplier
  scale[percent] <- .01
  extreme <- !is.finite(value) | abs(value) < .Machine$double.xmin
  value <- value * multiplier
  value[percent] <- value[percent] / 100
  # ponytail: only boundary inputs need decimal exponent adjustment; ordinary
  # values retain the established conversion and rounding path.
  if (any(extreme)) value[extreme] <- convert_cn_scaled_boundary(number_text[extreme], scale[extreme])
  reject(body_nonfinite & !is.finite(value), "value is outside the finite double range")
  reject(header_conflict, "explicit unit conflicts with the table-header unit")
  reject(!is.finite(value), "value is outside the finite double range")
  nonzero <- grepl("[1-9]", sub("[eE].*$", "", number_text))
  reject(value == 0 & nonzero, "nonzero value underflows the double range")
  negative <- sign_before == "-" | sign_after == "-" | accounting
  value[negative] <- -value[negative]
  output[active[matched]] <- value[matched]

  failed_local <- which(!matched)
  failed <- c(spacing_failed, syntax_failed, active[failed_local])
  if (length(failed) > 0L) {
    failure_reasons <- c(rep("digits use invalid whitespace grouping", length(spacing_failed)),
                        rep("value does not match the supported number syntax", length(syntax_failed)),
                        reasons[failed_local])
    failure_order <- order(failed)
    failed <- failed[failure_order]
    problems <- data.frame(
      index = failed,
      value = original[failed],
      reason = failure_reasons[failure_order],
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
  })
}

convert_cn_scaled_boundary <- function(text, scale) {
  vapply(seq_along(text), function(i) {
    parts <- strsplit(text[[i]], "[eE]", perl = TRUE)[[1L]]
    digits <- gsub(".", "", parts[[1L]], fixed = TRUE)
    first <- regexpr("[1-9]", digits)[[1L]]
    if (first < 0L) return(0)
    point <- regexpr(".", parts[[1L]], fixed = TRUE)[[1L]]
    integer_digits <- if (point < 0L) nchar(parts[[1L]]) else point - 1L
    exponent <- if (length(parts) == 2L) suppressWarnings(as.double(parts[[2L]])) else 0
    exponent <- exponent + integer_digits - first + round(log10(scale[[i]]))
    digits <- sub("0+$", "", substring(digits, first))
    mantissa <- paste0(substring(digits, 1L, 1L), ".", substring(digits, 2L))
    if (!is.finite(exponent)) return(if (exponent > 0) Inf else 0)
    suppressWarnings(as.double(paste0(mantissa, "e", sprintf("%.0f", exponent))))
  }, numeric(1))
}

normalize_cn_number_text <- function(x, argument = "x") {
  cn_encoding_call(.Call(C_normalize_characters, enc2utf8(x), TRUE), argument)
}

normalize_cn_number_characters <- function(x) {
  cn_encoding_call(.Call(C_normalize_characters, enc2utf8(x), FALSE))
}

has_invalid_cn_digit_spacing <- function(x, characters_normalized = FALSE) {
  if (!characters_normalized) x <- normalize_cn_number_characters(x)
  spacing <- "[[:space:]\u3000\u00a0\u202f]"
  has_digit_spacing <- grepl(
    paste0("[0-9]", spacing, "+[0-9]"),
    x,
    perl = TRUE
  )
  rows <- which(has_digit_spacing)
  has_digit_spacing[rows] <- !grepl(
    paste0(
      "^[^0-9.]*+",
      "[0-9]{1,3}+(?:", spacing, "++[0-9]{3})++",
      "(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?",
      "[^0-9]*$"
    ),
    x[rows],
    perl = TRUE
  )
  has_digit_spacing
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
