# Test-only reference: recursive calls and endpoints bypass the C fast paths.
# Long-decimal rounding is shared, with independent midpoint gold tests elsewhere.
native_r_reference <- function() {
  namespace <- asNamespace('cncleanr')
  reference <- new.env(parent = namespace)
  for (name in ls(namespace, all.names = TRUE)) {
    fun <- get(name, namespace)
    if (is.function(fun) && identical(environment(fun), namespace)) {
      environment(fun) <- reference
      reference[[name]] <- fun
    }
  }
  reference$.Call <- function(symbol, x, argument) {
    if (identical(symbol, cncleanr:::C_simple_numbers)) return(rep(NA_real_, length(x)))
    if (identical(symbol, cncleanr:::C_decimal_boundary)) return(base::.Call(symbol, x))
    stopifnot(identical(symbol, cncleanr:::C_normalize_characters))
    normalized <- chartr(
      '\uff0d\uff10\uff11\uff12\uff13\uff14\uff15\uff16\uff17\uff18\uff19\uff0e\uff0c\uff05\uff0b\uff08\uff09\uffe5\uff1c\uff1e\uff1d\uff25\uff45',
      '-0123456789.,%+()\u00a5<>=Ee', enc2utf8(x))
    normalized <- gsub('[\u2212\ufe63\u2013]', '-', normalized, perl = TRUE)
    if (argument) normalized <- gsub('[[:space:]\u3000\u00a0\u202f]+', '', normalized, perl = TRUE)
    normalized
  }
  reference
}

native_outcome <- function(fun, x, ...) {
  warnings <- character()
  result <- tryCatch(withCallingHandlers(fun(x, ...), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart('muffleWarning')
  }), error = function(e) list(error = conditionMessage(e)))
  list(result = result, warnings = warnings)
}

native_random_corpus <- function() {
  had_seed <- exists('.Random.seed', .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get('.Random.seed', .GlobalEnv)
  on.exit(if (had_seed) assign('.Random.seed', old_seed, .GlobalEnv) else
    rm(list = '.Random.seed', envir = .GlobalEnv))
  set.seed(20261012)
  n <- 3000L
  bodies <- c(sprintf('%.17g', runif(1000, -1e200, 1e200)),
    '0', '-0', '.25', '1.', '.', '1e-999', '1e309', '1,234', '1 234', '1 23',
    '1.7976931348623157e308', '4.9406564584124654e-324', '0x10', 'NaN', 'bad')
  formatted <- paste0(sample(c('', '+', '-', 'RMB', 'CNY-', '(', '\uffe5', '\u7ea6'), n, TRUE),
    sample(bodies, n, TRUE), sample(c('', '\u4e07', '\u4ebf\u5143', '\u5343\u5143', '%', ')', '\u5de6\u53f3', '\u4e07%'), n, TRUE))
  tokens <- c('1', '.', ',', '+', '-', 'e', 'E', '(', ')', '%', 'R', 'M', 'B',
    '\u4e07', '\u4ebf', '\u5143', '\uff11', '\uff0e', '\u00a0', '\u202f', '\u3000', '\U0001f600')
  noise <- replicate(500, paste0(sample(tokens, sample.int(24, 1), TRUE), collapse = ''))
  ranges <- paste0(sample(bodies, 500, TRUE), sample(c('-', '~', '\u81f3'), 500, TRUE),
    sample(bodies, 500, TRUE), sample(c('', '\u4e07', '%'), 500, TRUE))
  x <- c(formatted, noise, ranges, NA, '', 'R', 'RM', 'C', 'CN', '(', '+', '-',
    ' \uff11\uff12\uff0e\uff15\uff05 ', '\u7ea615%\u5de6\u53f3', '3-5\u4e07',
    strrep('9', 10000), paste0('1', strrep('0', 10000), 'e-10000'),
    paste0('3\u4e07', strrep('\U0001f600', 10000)), strrep('-', 32))
  setNames(x, paste0('row', seq_along(x)))
}

test_that('fixed-seed native and R paths agree on complete parser outcomes', {
  reference <- native_r_reference()
  x <- native_random_corpus()
  for (kind in c('number', 'quantity', 'range')) {
    name <- paste0('parse_cn_', kind)
    actual <- get(name, asNamespace('cncleanr'))
    expected <- reference[[name]]
    for (input in list(x, factor(x), rep(x[1:40], 30), character(),
                      c(negative_zero = -0, positive = Inf, missing = NA, nan = NaN))) {
      expect_identical(native_outcome(actual, input), native_outcome(expected, input), info = name)
      expect_identical(native_outcome(actual, input, strict = TRUE),
                       native_outcome(expected, input, strict = TRUE), info = name)
    }
    expect_identical(native_outcome(actual, x, na = c('', 'bad', '\uff11', '3-5\u4e07')),
                     native_outcome(expected, x, na = c('', 'bad', '\uff11', '3-5\u4e07')), info = name)
  }
  for (unit in c('\u5143', '\u5343\u5143', '\u4e07', '\u4e07\u5143',
                 '\u4ebf', '\u4ebf\u5143', '\u4e07\u4ebf', '\u4e07\u4ebf\u5143')) {
    expect_identical(native_outcome(parse_cn_number, x, unit = unit),
                     native_outcome(reference$parse_cn_number, x, unit = unit), info = unit)
  }
  native <- .Call(cncleanr:::C_simple_numbers, x, NA_real_)
  handled <- which(!is.na(native))
  gold <- suppressWarnings(reference$parse_cn_number(x))
  expect_gt(length(handled), 0L)
  expect_identical(native[handled], as.numeric(gold)[handled])
  expect_identical(1 / native[handled], 1 / as.numeric(gold)[handled])
  expect_false(any(handled %in% cn_problems(gold)$index))
})

test_that('malformed UTF-8 is rejected by normalization and every public parser', {
  malformed <- lapply(list(c(0x80), c(0xc0, 0xb1), c(0xc2), c(0xe0),
    c(0xe0, 0xa0), c(0xef, 0xbc), c(0xe0, 0x80, 0xb1), c(0xed, 0xa0, 0x80),
    c(0xf0, 0x80, 0x80, 0xb1), c(0xf0, 0x90, 0x80), c(0xf4, 0x90, 0x80, 0x80),
    c(0xf5, 0x80, 0x80, 0x80)), function(bytes) {
      x <- rawToChar(as.raw(bytes))
      Encoding(x) <- 'UTF-8'
      x
    })
  for (x in malformed) {
    expect_false(validUTF8(x))
    for (strip in c(FALSE, TRUE))
      expect_error(.Call(cncleanr:::C_normalize_characters, c('1', x), strip), 'Invalid UTF-8')
    for (parser in list(parse_cn_number, parse_cn_quantity, parse_cn_range)) {
      expect_error(parser(c('1', x)), 'Invalid UTF-8')
      expect_error(parser('1', na = x), 'Invalid UTF-8')
    }
  }
})

test_that('normalization handles short strings, encodings and buffer boundaries', {
  reference <- native_r_reference()
  latin <- iconv('\u00a51', from = 'UTF-8', to = 'latin1')
  Encoding(latin) <- 'latin1'
  x <- c('', NA, 'R', 'RM', 'C', 'CN', '(', '+', '-', '\u00a5', latin,
    '\uff11', '\u4e07', '\U0001f600', '\U00020000', '\U0010fffd',
    ' \uff11\t\uff0e\uff12\u202f\u4e07 ', strrep('\uff11\U0001f600\u2212', 20000))
  names(x) <- seq_along(x)
  for (strip in c(FALSE, TRUE)) {
    expect_identical(.Call(cncleanr:::C_normalize_characters, x, strip),
                     reference$.Call(cncleanr:::C_normalize_characters, x, strip))
    expect_identical(.Call(cncleanr:::C_normalize_characters, rev(x), strip),
                     reference$.Call(cncleanr:::C_normalize_characters, rev(x), strip))
  }
  expect_identical(.Call(cncleanr:::C_simple_numbers, character(), NA_real_), numeric())
  bytes <- '\xff'
  Encoding(bytes) <- 'bytes'
  expect_identical(.Call(cncleanr:::C_simple_numbers, bytes, NA_real_), NA_real_)
  expect_error(.Call(cncleanr:::C_normalize_characters, bytes, TRUE), 'bytes encoding')
  for (header in list(NULL, integer(1), numeric(), c(1, 2), '1'))
    expect_error(.Call(cncleanr:::C_simple_numbers, '1', header), 'Invalid native')
  for (strip in list(NULL, 1, logical(), c(TRUE, FALSE), NA))
    expect_error(.Call(cncleanr:::C_normalize_characters, '1', strip), 'Invalid normalization')
})
