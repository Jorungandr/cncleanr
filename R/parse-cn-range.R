#' Parse Numeric Ranges Used in Chinese Data
#'
#' Converts closed ranges such as `"3\u4e07-5\u4e07"` and open bounds such as
#' `"10\u4e07\u5143\u4ee5\u4e0a"` into explicit lower and upper bounds. A shared suffix in
#' `"3-5\u4e07"` is applied to both endpoints. Signs used by negative numbers and
#' scientific notation are distinguished from range separators.
#' Digit grouping is validated independently at each range endpoint, so
#' `"1 234-2 345"` is accepted but `"1 23-2 345"` is not.
#' Endpoint missing markers are checked before and after shared-unit propagation.
#' Shared suffixes are recognized and inserted inside accounting parentheses,
#' preserving their negative sign. For example, `"(3\u4e07)-5"` spans -30000 to 50000.
#' Specific scalar failures retain their original reason. Uniquely split failed
#' ranges identify left/right endpoint causes where available; ambiguous splits,
#' missing endpoints and digit-grouping failures retain conservative diagnostics.
#'
#' @inheritParams parse_cn_number
#' @param x A character, factor, or numeric vector. Matrices and arrays are
#'   rejected; select one column explicitly. Numeric input is converted
#'   to double and otherwise passed through unchanged when `unit = NULL`,
#'   including `Inf`, `-Inf`, and `NaN`. Header-unit conversion follows
#'   [parse_cn_number()].
#'   Conversion methods must return a plain double vector of the original length,
#'   without a class or dimensions; malformed results cause an error.
#'   SPSS user-defined missing metadata is respected. Objects with class `units`
#'   are rejected: convert units explicitly, then call `units::drop_units()`.
#'
#' @return A data frame with columns `lower`, `upper`, `lower_inclusive`, and
#'   `upper_inclusive`. Numeric input becomes an inclusive point range,
#'   including numeric `Inf` and `-Inf` when `unit = NULL`; `NA` and `NaN` have missing
#'   inclusivity. Infinite bounds created from textual inequalities represent
#'   open-ended bounds and are distinct from numeric point inputs. With a header
#'   unit, nonfinite or overflowing numeric inputs become diagnosed failures;
#'   infinite open ends created by textual inequalities are retained.
#' @details Explicit compound endpoints use the grammar in [parse_cn_number()].
#'   When either endpoint is compound, the opposite endpoint must specify its
#'   own trailing unit; no scale is inferred from the compound's final term.
#'
#' @usage
#' parse_cn_range(
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
#' parse_cn_range(c("3\u4e07-5\u4e07", "3-5\u4e07", "10\u4e07\u5143\u4ee5\u4e0a"))
#'
#' @export
parse_cn_range <- function(
  x,
  na = c(
    "", "NA", "N/A", "\u6682\u65e0", "\u672a\u516c\u5e03",
    "\u2014", "\u2013", "-", "...", "\u2026"
  ),
  strict = FALSE,
  unit = NULL
) {
  cn_with_encoding_context(x, na, {
  validate_cn_parse_arguments(x, na, strict)
  if (!is.null(unit)) cn_header_multiplier(unit)
  x <- prepare_cn_parse_input(x)

  if (is.numeric(x)) {
    value <- if (is.null(unit)) cn_numeric_values(x) else
      suppressWarnings(parse_cn_number(x, na = na, unit = unit))
    present <- !is.na(value)
    result <- data.frame(
      lower = as.numeric(value),
      upper = as.numeric(value),
      lower_inclusive = ifelse(present, TRUE, NA),
      upper_inclusive = ifelse(present, TRUE, NA)
    )
    if (!is.null(unit)) return(apply_cn_problems(result, cn_problems(value), strict))
    return(result)
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
  characters <- normalize_cn_number_characters(x)
  invalid_spacing <- has_invalid_cn_digit_spacing(characters, characters_normalized = TRUE)
  normalized <- normalize_cn_number_text(characters)
  normalized_na <- normalize_cn_number_text(na, argument = "na")
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
    obvious_range <- grepl(paste0(
      "^[0-9]+(?:\\.[0-9]+)?(?:(?:\u4e07\u4ebf|\u4e07|\u4ebf)(?:\u5143)?|[\u767e\u5343]\u5143|\u5143|%)?",
      "[\u81f3\u5230~\uff5e\u2014\u2013-][0-9]"), unique_text, perl = TRUE)
    quantity_rows <- which(!obvious_range)
    quantity <- suppressWarnings(parse_cn_quantity(unique_text[quantity_rows], na = normalized_na, unit = unit))
    quantity_problems <- cn_problems(quantity)
    local_failed <- quantity_problems$index
    quantity_failed <- sort(c(which(obvious_range), quantity_rows[local_failed]))
    local_ok <- setdiff(seq_along(quantity_rows), local_failed)
    quantity_ok <- quantity_rows[local_ok]

    qualifier <- quantity$qualifier[local_ok]
    approximate <- quantity_ok[qualifier %in% "approx"]
    unique_reason[approximate] <- "an approximate value does not define explicit bounds"
    bounded_local <- which(qualifier %in%
      c("exact", "at_least", "greater_than", "at_most", "less_than"))
    bounded <- quantity_ok[bounded_local]
    value <- quantity$value[local_ok[bounded_local]]
    qualifier <- qualifier[bounded_local]
    unique_output$lower[bounded] <- ifelse(
      qualifier %in% c("at_most", "less_than"), -Inf, value)
    unique_output$upper[bounded] <- ifelse(
      qualifier %in% c("at_least", "greater_than"), Inf, value)
    unique_output$lower_inclusive[bounded] <- qualifier %in% c("exact", "at_least")
    unique_output$upper_inclusive[bounded] <- qualifier %in% c("exact", "at_most")

    if (length(quantity_failed) > 0L) {
      ranges <- find_cn_range_endpoints_batch(
        unique_text[quantity_failed],
        normalized_na, unit = unit
      )
      unique_reason[quantity_failed] <- ranges$reason
      # A failed scalar can resemble a range (e.g. the minus in 1e-330).
      # Reuse its specific cause rather than replacing it with a generic fallback.
      scalar_rows <- quantity_rows[local_failed]
      restore <- which(unique_reason[scalar_rows] %in% c(
        "value is not a supported range or bound", "one or both range endpoints are invalid") &
        quantity_problems$reason != "value does not match the supported number syntax")
      unique_reason[scalar_rows[restore]] <- quantity_problems$reason[restore]
      valid_range <- is.na(ranges$reason)
      reversed <- which(valid_range & ranges$values[, 1L] > ranges$values[, 2L])
      unique_reason[quantity_failed[reversed]] <- "range lower bound is greater than its upper bound"
      valid_range[reversed] <- FALSE
      rows <- quantity_failed[valid_range]
      unique_output$lower[rows] <- ranges$values[valid_range, 1L]
      unique_output$upper[rows] <- ranges$values[valid_range, 2L]
      unique_output$lower_inclusive[rows] <- TRUE
      unique_output$upper_inclusive[rows] <- TRUE
    }

    output[active, ] <- unique_output[active_map, , drop = FALSE]
    problem_reason[active] <- unique_reason[active_map]
  }

  # A whole-string grouping check cannot validate two numbers. Retry rejected
  # rows with original endpoint spacing; never concatenate their digits first.
  spaced <- which(invalid_spacing)
  if (length(spaced)) {
    ranges <- find_cn_range_endpoints_batch(characters[spaced], normalized_na,
                                           normalize_suffix = TRUE, unit = unit)
    endpoint_reason <- ranges$reason
    specific <- !is.na(endpoint_reason) & endpoint_reason != "value is not a supported range or bound"
    problem_reason[spaced[specific]] <- endpoint_reason[specific]
    valid <- which(is.na(ranges$reason))
    reversed <- valid[ranges$values[valid, 1L] > ranges$values[valid, 2L]]
    problem_reason[spaced[reversed]] <- "range lower bound is greater than its upper bound"
    valid <- setdiff(valid, reversed)
    rows <- spaced[valid]
    output$lower[rows] <- ranges$values[valid, 1L]
    output$upper[rows] <- ranges$values[valid, 2L]
    output$lower_inclusive[rows] <- output$upper_inclusive[rows] <- TRUE
    problem_reason[rows] <- NA_character_
  }

  failed <- which(!is.na(problem_reason))
  problems <- data.frame(
    index = failed,
    value = original[failed],
    reason = problem_reason[failed],
    stringsAsFactors = FALSE
  )
  apply_cn_problems(output, problems, strict)
  })
}

find_cn_range_endpoints_batch <- function(text, na, normalize_suffix = FALSE, unit = NULL) {
  size <- length(text)
  values <- matrix(NA_real_, nrow = size, ncol = 2L)
  reason <- rep("one or both range endpoints are invalid", size)
  separator <- "[\u81f3\u5230~\uff5e\u2014\u2013-]"
  # ponytail: valid grammar has at most five signs/separators; a cap of eight
  # bounds substring expansion without imposing a cell-length restriction.
  separator_count <- lengths(regmatches(text, gregexpr(separator, text, perl = TRUE)))
  excessive <- separator_count > 8L
  reason[excessive] <- "range contains too many separators"
  text[excessive] <- ""
  first <- regexpr(separator, text, perl = TRUE)
  reason[first < 0L & !excessive] <- "value is not a supported range or bound"
  right <- substring(text, pmax(first + 1L, 1L))
  single <- which(first > 1L & nzchar(right) & !grepl(separator, right, perl = TRUE))
  complex <- setdiff(which(first > 0L), single)
  positions_by_text <- gregexpr(separator, text[complex], perl = TRUE)
  capacity <- length(single) + sum(lengths(positions_by_text))
  candidate_source <- integer(capacity)
  candidate_left <- character(capacity)
  candidate_right <- character(capacity)
  candidate_count <- length(single)
  if (candidate_count) {
    endpoints <- propagate_cn_range_suffix(substring(text[single], 1L, first[single] - 1L),
                                          right[single], normalize_suffix, na)
    candidate_source[seq_len(candidate_count)] <- single
    candidate_left[seq_len(candidate_count)] <- endpoints$left
    candidate_right[seq_len(candidate_count)] <- endpoints$right
  }

  for (j in seq_along(complex)) {
    i <- complex[[j]]
    positions <- positions_by_text[[j]]
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
      endpoints <- propagate_cn_range_suffix(left, right, normalize_suffix, na)
      candidate_count <- candidate_count + 1L
      candidate_source[[candidate_count]] <- i
      candidate_left[[candidate_count]] <- endpoints$left
      candidate_right[[candidate_count]] <- endpoints$right
    }
  }

  if (candidate_count == 0L) {
    return(list(values = values, reason = reason))
  }
  used <- seq_len(candidate_count)
  candidate_source <- candidate_source[used]
  candidate_left <- candidate_left[used]
  candidate_right <- candidate_right[used]

  endpoint_text <- as.vector(rbind(candidate_left, candidate_right))
  parsed <- suppressWarnings(parse_cn_number(endpoint_text, na = na, unit = unit))
  endpoint_problems <- cn_problems(parsed)
  invalid_endpoint <- rep(FALSE, length(parsed))
  invalid_endpoint[endpoint_problems$index] <- TRUE
  invalid_endpoint[is.na(parsed)] <- TRUE
  candidate_valid <-
    !invalid_endpoint[seq.int(1L, length(parsed), by = 2L)] &
    !invalid_endpoint[seq.int(2L, length(parsed), by = 2L)]
  if (nrow(endpoint_problems)) {
    # Only failed, uniquely split candidates get labels; never guess from an
    # exponent sign, multiple splits, or NA endpoints lacking a diagnosed cause.
    unique_split <- tabulate(candidate_source, nbins = size)[candidate_source] == 1L &
      !grepl("[eE]$", candidate_left)
    detail <- rep(NA_character_, length(parsed))
    detail[endpoint_problems$index] <- paste0(
      ifelse(endpoint_problems$index %% 2L == 1L, "left", "right"),
      " range endpoint: ", endpoint_problems$reason)
    left_reason <- detail[seq.int(1L, length(parsed), by = 2L)]
    right_reason <- detail[seq.int(2L, length(parsed), by = 2L)]
    left_only <- which(unique_split & !is.na(left_reason) & is.na(right_reason))
    right_only <- which(unique_split & is.na(left_reason) & !is.na(right_reason))
    both <- which(unique_split & !is.na(left_reason) & !is.na(right_reason))
    reason[candidate_source[left_only]] <- left_reason[left_only]
    reason[candidate_source[right_only]] <- right_reason[right_only]
    reason[candidate_source[both]] <- paste(left_reason[both], right_reason[both], sep = "; ")
  }
  percent_left <- grepl("%\\)?$", normalize_cn_number_text(candidate_left))
  percent_right <- grepl("%\\)?$", normalize_cn_number_text(candidate_right))
  incompatible <- candidate_valid & xor(percent_left, percent_right)
  candidate_valid[incompatible] <- FALSE
  reason[unique(candidate_source[incompatible])] <- "range endpoints use incompatible units"
  grouping <- endpoint_problems$index[
    endpoint_problems$reason == "digits use invalid whitespace grouping"]
  if (length(grouping)) {
    bad_candidates <- unique((grouping + 1L) %/% 2L)
    reason[unique(candidate_source[bad_candidates])] <- "digits use invalid whitespace grouping"
  }
  parsed <- matrix(as.numeric(parsed), ncol = 2L, byrow = TRUE)

  counts <- tabulate(candidate_source[candidate_valid], nbins = size)
  accepted <- which(candidate_valid & counts[candidate_source] == 1L)
  values[candidate_source[accepted], ] <- parsed[accepted, , drop = FALSE]
  reason[counts == 1L] <- NA_character_
  reason[counts > 1L] <- "range contains more than one valid separator"

  list(values = values, reason = reason)
}

propagate_cn_range_suffix <- function(left, right, normalize_suffix = FALSE, na = character()) {
  suffix_pattern <- paste0(
    "((?:\u4e07\u4ebf|\u4e07|\u4ebf)(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)?|[\u767e\u5343]\u5143|",
    "(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)|%)$"
  )
  text <- c(left, right)
  if (normalize_suffix) text <- normalize_cn_number_text(text)
  missing <- text %in% na
  wrapped <- startsWith(text, "(") & endsWith(text, ")")
  if (any(wrapped)) text[wrapped] <- substring(text[wrapped], 2L, nchar(text[wrapped]) - 1L)
  matches <- regexpr(suffix_pattern, text, perl = TRUE)
  suffixes <- rep("", length(text))
  present <- which(matches > 0L)
  suffixes[present] <- substring(text[present], matches[present],
    matches[present] + attr(matches, "match.length")[present] - 1L)
  left_suffix <- suffixes[seq_along(left)]
  right_suffix <- suffixes[length(left) + seq_along(right)]
  add_left <- !nzchar(left_suffix) & nzchar(right_suffix)
  add_right <- nzchar(left_suffix) & !nzchar(right_suffix)
  # Never infer a bare endpoint's scale from the small final term of a compound.
  compound <- grepl("(?:\u4e07\u4ebf|\u4ebf|\u4e07)[0-9.]", text, perl = TRUE)
  ambiguous <- rep(FALSE, length(left))
  if (any(compound)) {
    explicit <- nzchar(suffixes) | grepl(paste0(
      substr(suffix_pattern, 1L, nchar(suffix_pattern) - 1L), "\\)$"), text, perl = TRUE)
    explicit_left <- explicit[seq_along(left)]
    explicit_right <- explicit[length(left) + seq_along(right)]
    add_left <- add_left & !explicit_left
    add_right <- add_right & !explicit_right
    ambiguous <- (compound[seq_along(left)] & !explicit_right) |
      (compound[length(left) + seq_along(right)] & !explicit_left)
  }
  if (any(wrapped)) {
    rows <- which(wrapped & c(add_left, add_right))
    if (length(rows)) {
      raw <- trimws(c(left, right)[rows], whitespace = "[[:space:]\u3000\u00a0\u202f]")
      suffix <- c(right_suffix, left_suffix)[rows]
      fixed <- paste0(substr(raw, 1L, nchar(raw) - 1L), suffix, ")")
      in_left <- rows <= length(left)
      left[rows[in_left]] <- fixed[in_left]
      right[rows[!in_left] - length(left)] <- fixed[!in_left]
    }
    add_left <- add_left & !wrapped[seq_along(left)]
    add_right <- add_right & !wrapped[length(left) + seq_along(right)]
  }
  left[add_left] <- paste0(left[add_left], right_suffix[add_left])
  right[add_right] <- paste0(right[add_right], left_suffix[add_right])
  left[ambiguous] <- right[ambiguous] <- NA_character_
  # Appending a shared unit must not resurrect an original missing endpoint.
  left[missing[seq_along(left)]] <- NA_character_
  right[missing[length(left) + seq_along(right)]] <- NA_character_
  list(left = left, right = right)
}
