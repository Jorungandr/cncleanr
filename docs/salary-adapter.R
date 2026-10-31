# Example only: source this file explicitly. Not an exported cncleanr API.
# Input is a complete, caller-selected salary field, not a recruitment article.
salary_example <- function(x, context_period = NULL, currency = NULL,
                           na = c('', 'NA', 'N/A', '暂无', '未公布', '-', '—', '…')) {
  if ((!is.character(x) && !is.factor(x)) || !is.null(dim(x)))
    stop('`x` must be a character or factor vector without dimensions.', call. = FALSE)
  scalar_text <- function(value) is.character(value) && length(value) == 1L &&
    is.null(dim(value)) && !is.na(value)
  if (!is.null(context_period) &&
      (!scalar_text(context_period) || !context_period %in% c('hour','day','month','year')))
    stop('`context_period` must be NULL or hour/day/month/year.', call. = FALSE)
  if (!is.null(currency) && (!scalar_text(currency) || !grepl('^[A-Z]{3}$', currency)))
    stop('`currency` must be NULL or a three-uppercase-letter source label.', call. = FALSE)
  if (!is.character(na) || !is.null(dim(na)))
    stop('`na` must be a character vector without dimensions.', call. = FALSE)
  normalize <- function(value) {
    value <- chartr('－０１２３４５６７８９．，％＋（）／Ｋｋ', '-0123456789.,%+()/Kk', enc2utf8(value))
    value <- gsub('[\u2212\u2013\u2014]', '-', value, perl = TRUE)
    trimws(value, whitespace = '[[:space:]\u3000\u00a0\u202f]')
  }
  raw <- unname(as.character(x))
  work <- normalize(raw)
  n <- length(raw)
  data <- data.frame(index = seq_len(n), raw = raw, lower = rep(NA_real_, n),
    upper = rep(NA_real_, n), lower_inclusive = rep(NA, n), upper_inclusive = rep(NA, n),
    period = rep(if (is.null(context_period)) NA_character_ else context_period, n),
    advertised_payments = rep(NA_integer_, n),
    currency = rep(if (is.null(currency)) NA_character_ else currency, n),
    status = rep('invalid', n), stringsAsFactors = FALSE)
  reason <- rep('Salary field does not match the supported syntax.', n)
  missing <- is.na(work) | work %in% normalize(na)
  data$status[missing] <- 'missing'
  reason[missing] <- ''
  work[is.na(work)] <- ''
  negotiated <- !missing & work %in% c('面议','面議','待遇面议','待遇面議','薪资面议','薪資面議')
  data$status[negotiated] <- 'negotiated'
  reason[negotiated] <- 'Negotiated pay is not a numeric amount.'
  conditional <- !missing & !negotiated & grepl(
    '底薪|提成|奖金|獎金|绩效|績效|试用|試用|转正|轉正|税前|税后|稅前|稅後|综合|綜合|按实际|按實際|面议|面議|面谈|面談|周结|周結|週結|日结|日結', work)
  data$status[conditional] <- 'conditional'
  reason[conditional] <- 'Pay has additional conditions or components; review the complete source.'
  active <- which(!missing & !negotiated & !conditional)
  text <- work[active]
  # A separator is mandatory before N薪. Never split an unseparated digit run.
  pay_pattern <- '(?:[[:space:]]*[·*][[:space:]]*|[[:space:]]+)([0-9]+)薪$'
  pay <- grepl(pay_pattern, text, perl = TRUE)
  payments <- rep(NA_real_, length(active))
  payments[pay] <- as.double(sub(paste0('(?s)^.*', pay_pattern), '\\1', text[pay], perl = TRUE))
  valid_pay <- !pay | (is.finite(payments) & payments > 0 & payments <= .Machine$integer.max)
  good_pay <- which(pay & valid_pay)
  data$advertised_payments[active[good_pay]] <- as.integer(payments[good_pay])
  text <- normalize(sub(pay_pattern, '', text, perl = TRUE))
  prefix_pattern <- '^(每小时|每小時|时薪|時薪|日薪|月薪|年薪)(?:为|為)?[[:space:]]*'
  prefix <- rep(NA_character_, length(active))
  found <- grepl(prefix_pattern, text, perl = TRUE)
  prefix[found] <- sub(paste0('(?s)', prefix_pattern, '.*$'), '\\1', text[found], perl = TRUE)
  prefix <- unname(c('每小时'='hour','每小時'='hour','时薪'='hour','時薪'='hour',
                    '日薪'='day','月薪'='month','年薪'='year')[prefix])
  text <- normalize(sub(prefix_pattern, '', text, perl = TRUE))
  suffix_pattern <- '/[[:space:]]*(小时|小時|时|時|天|日|月|年)$'
  suffix <- rep(NA_character_, length(active))
  found <- grepl(suffix_pattern, text, perl = TRUE)
  suffix[found] <- sub(paste0('(?s)^.*', suffix_pattern), '\\1', text[found], perl = TRUE)
  suffix <- unname(c('小时'='hour','小時'='hour','时'='hour','時'='hour',
                    '天'='day','日'='day','月'='month','年'='year')[suffix])
  text <- normalize(sub(suffix_pattern, '', text, perl = TRUE))
  conflict <- !is.na(prefix) & !is.na(suffix) & prefix != suffix
  period <- ifelse(!is.na(prefix), prefix, suffix)
  if (!is.null(context_period)) {
    conflict <- conflict | (!is.na(period) & period != context_period)
    period[is.na(period)] <- context_period
  }
  data$period[active] <- period
  currency_conflict <- rep(FALSE, length(active))
  if (!is.null(currency))
    currency_conflict <- (currency != 'CNY' & grepl('人民币|RMB', text)) |
      (!currency %in% c('CNY','JPY') & grepl('[¥￥]', text))
  reason[active[conflict]] <- 'Explicit pay periods conflict with each other or the supplied context.'
  reason[active[!valid_pay]] <- 'Advertised payment count must be a positive representable integer.'
  reason[active[currency_conflict]] <- 'Explicit RMB conflicts with the supplied currency label.'
  candidates <- which(!conflict & valid_pay & !currency_conflict)
  if (length(candidates)) {
    amount <- gsub('(?<=[0-9.])[Kk]', '千元', text[candidates], perl = TRUE)
    # In salary fields a trailing plus can hide an unspecified pay component.
    trailing_plus <- grepl('[+][[:space:]]*$', amount)
    # All candidates share a single core call. No private cncleanr symbols.
    parsed <- suppressWarnings(cncleanr::parse_cn_range(amount))
    problems <- cncleanr::cn_problems(parsed)
    invalid <- is.na(parsed$lower) | is.na(parsed$upper) | grepl('%', amount, fixed = TRUE)
    nonpositive <- (is.finite(parsed$lower) & parsed$lower <= 0) |
      (is.finite(parsed$upper) & parsed$upper <= 0)
    invalid <- invalid | nonpositive | trailing_plus
    indices <- active[candidates]
    data$status[indices[trailing_plus]] <- 'conditional'
    reason[indices[trailing_plus]] <- 'A trailing plus may denote unspecified pay components; review the source.'
    reason[indices[problems$index]] <- problems$reason
    reason[indices[nonpositive]] <- 'Zero or negative salary amounts need source review.'
    missing_period <- is.na(period[candidates]) & !invalid
    data$status[indices[missing_period]] <- 'needs_context'
    reason[indices[missing_period]] <- 'Pay period is not explicit; supply documented context.'
    incompatible_pay <- pay[candidates] & !is.na(period[candidates]) & period[candidates] != 'month' & !invalid
    data$status[indices[incompatible_pay]] <- 'conditional'
    reason[indices[incompatible_pay]] <- 'Advertised N-pay terms require monthly context; no conversion was made.'
    accepted <- which(!invalid & !missing_period & !incompatible_pay)
    target <- indices[accepted]
    data[target, c('lower','upper','lower_inclusive','upper_inclusive')] <-
      parsed[accepted, c('lower','upper','lower_inclusive','upper_inclusive')]
    data$status[target] <- 'parsed'
    reason[target] <- ''
  }
  review <- data[!data$status %in% c('parsed','missing'), c('index','raw'), drop = FALSE]
  review$reason <- reason[review$index]
  rownames(review) <- NULL
  list(data = data, review = review)
}
