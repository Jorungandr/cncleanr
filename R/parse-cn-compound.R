# Called only after ordinary whole-number syntax fails. Components are single
# terms, so the existing parser remains the conversion/overflow oracle.
parse_cn_compound <- function(text, accounting, header_multiplier) {
  result <- list(value = rep(NA_real_, length(text)),
    reason = rep("value does not match the supported number syntax", length(text)))
  if (!length(text)) return(result)
  number <- "(?:(?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\\.[0-9]+)?|\\.[0-9]+)"
  magnitude <- "(?:\u4e07\u4ebf|\u4ebf|\u4e07)"
  currency <- "(?:\u4eba\u6c11\u5e01|\u5757\u94b1|\u5143|\u5757)"
  term <- paste0(number, magnitude)
  pattern <- paste0("^([+-]?)(\u00a5|\u4eba\u6c11\u5e01|(?i:RMB|CNY))?([+-]?)",
    "((?:", term, "){2,3})(", currency, ")?$")
  matches <- regexpr(pattern, text, perl = TRUE)
  rows <- which(matches > 0L)
  if (!length(rows)) return(result)
  starts <- attr(matches, "capture.start")[rows, , drop = FALSE]
  sizes <- attr(matches, "capture.length")[rows, , drop = FALSE]
  fields <- lapply(1:5, function(j) substring(text[rows], starts[, j], starts[, j] + sizes[, j] - 1L))
  parts <- regmatches(fields[[4L]], gregexpr(term, fields[[4L]], perl = TRUE))
  flat <- unlist(parts, use.names = FALSE)
  owner <- rep(seq_along(rows), lengths(parts))
  position <- cbind(owner, sequence(lengths(parts)))
  ranks <- matrix(4L, nrow = length(rows), ncol = 3L)
  suffix <- sub(paste0("^.*?(", magnitude, ")$"), "\\1", flat, perl = TRUE)
  ranks[position] <- match(suffix, c("\u4e07\u4ebf", "\u4ebf", "\u4e07"))
  reason <- rep(NA_character_, length(rows))
  reject <- function(condition, message) {
    reason[is.na(reason) & condition] <<- message
  }
  reject(nzchar(fields[[1L]]) & nzchar(fields[[3L]]),
    "a value cannot contain more than one explicit sign")
  reject(accounting[rows] & (nzchar(fields[[1L]]) | nzchar(fields[[3L]])),
    "accounting parentheses cannot contain an explicit sign")
  reject(ranks[, 1L] >= ranks[, 2L] | ranks[, 2L] >= ranks[, 3L],
    "compound magnitudes must be distinct and descending")
  reject(!is.null(header_multiplier), "compound quantity conflicts with the table-header unit")
  parsed <- suppressWarnings(parse_cn_number(flat, na = character()))
  problems <- cn_problems(parsed)
  failed <- owner[problems$index]
  first <- which(!duplicated(failed))
  keep <- first[is.na(reason[failed[first]])]
  reason[failed[keep]] <- problems$reason[keep]
  values <- matrix(0, nrow = length(rows), ncol = 3L)
  values[position] <- as.numeric(parsed)
  total <- rowSums(values)
  reject(!is.finite(total), "value is outside the finite double range")
  negative <- accounting[rows] | fields[[1L]] == "-" | fields[[3L]] == "-"
  total[negative] <- -total[negative]
  result$value[rows[is.na(reason)]] <- total[is.na(reason)]
  result$reason[rows] <- reason
  result
}
