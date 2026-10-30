# Rscript docs/salary-adapter-audit.R <installed-library>
source('docs/audit-setup.R')
source('docs/salary-adapter.R', encoding = 'UTF-8')
checks <- 0L
check <- function(ok, label) {
  checks <<- checks + 1L
  if (!isTRUE(ok)) stop('Salary audit failed: ', label, call. = FALSE)
}
bad <- function(code) inherits(tryCatch(force(code), error = identity), 'error')

# Synthetic boundary cases, separate from the source-fragment cases below.
x <- c('月薪3-5万元', '15K-25K/月 · 13薪', '每小时35—40元', '年薪为20-30万元',
       '日薪140-160元', '时薪20元', '3万元以上/月', '月薪小于5000元',
       '月薪５千元', '月薪1 234元', '月薪1e3元', '月薪1.5k', '月薪3万-5万元')
r <- salary_example(x)
check(identical(r$data$status, rep('parsed', length(x))), 'supported statuses')
check(identical(r$data$lower, c(30000,15000,35,200000,140,20,30000,-Inf,5000,1234,1000,1500,30000)), 'independent lower')
check(identical(r$data$upper, c(50000,25000,40,300000,160,20,Inf,5000,5000,1234,1000,1500,50000)), 'independent upper')
check(identical(r$data$period, c('month','month','hour','year','day','hour',rep('month',7))), 'explicit periods')
check(identical(which(!r$data$lower_inclusive), 8L), 'open lower bound')
check(identical(which(!r$data$upper_inclusive), c(7L,8L)), 'open upper bounds')
check(r$data$advertised_payments[2L] == 13 && sum(!is.na(r$data$advertised_payments)) == 1L, 'payment declaration')
check(all(is.na(r$data$currency)) && nrow(r$review) == 0L, 'no currency inference')

unsafe <- c('15-25K·13薪', '15-25K', '底薪5000+提成', '面议',
 '试用期3500元/月，转正后3700-4500元/月', '月薪3-5万（按实际工作时间计算）',
 '年薪20万元·13薪', '月薪3-5万元/年', '月薪0元', '月薪-3000元',
 '月薪1 23元', '月薪5000元包吃住', '月薪约5000元', '月薪15W',
 '月薪2M', '月薪5%', '月薪3000元·0薪', '月薪3000元·13薪·14薪',
 '时薪20元/周', '月薪暂无', '月薪15K元', '月薪3-5万/小时',
 '月薪1e309元', '月薪1e-999元', '月薪3000元·2147483648薪', '月薪3000元周结')
r <- salary_example(unsafe)
check(identical(r$data$status[1:4], c('needs_context','needs_context','conditional','negotiated')), 'review categories')
check(all(r$data$status != 'parsed'), 'unsafe inputs never accepted')
check(all(is.na(r$data$lower)) && all(is.na(r$data$upper)), 'review values withheld')
check(identical(r$review$index, seq_along(unsafe)) && identical(r$review$raw, unsafe), 'review provenance')
check(all(nzchar(r$review$reason)), 'review reasons')
check(r$data$advertised_payments[1L] == 13, 'declaration retained without period')

r <- salary_example(c('15-25K·13薪','20-30K'), context_period = 'month', currency = 'CNY')
check(identical(r$data$lower, c(15000,20000)) && identical(r$data$upper, c(25000,30000)), 'explicit context')
check(identical(r$data$currency, c('CNY','CNY')), 'explicit currency')
check(salary_example('时薪20元', context_period='month')$data$status == 'invalid', 'context conflict')
check(salary_example('月薪RMB3000', currency='USD')$data$status == 'invalid', 'currency conflict')
check(salary_example('月薪￥3000', currency='USD')$data$status == 'invalid', 'currency symbol conflict')
check(identical(salary_example(c('月薪3\n000元','3\n000元/月'))$data$lower,c(3000,3000)), 'multiline grouping retains period')
for (input in list(character(), factor(character()))) {
  z <- salary_example(input)
  check(nrow(z$data) == 0L && nrow(z$review) == 0L, 'empty schema')
}
r <- salary_example(c(NA, '', '暂无', '-', '面议'))
check(identical(r$data$status, c(rep('missing',4),'negotiated')) && identical(r$review$index, 5L), 'missing versus negotiated')
check(salary_example('月薪3000', na='月薪3000')$data$status == 'missing', 'original marker first')
check(salary_example('暂无', na=character())$data$status == 'invalid', 'no marker resurrection')
check(salary_example('面议', na='面议')$data$status == 'missing', 'explicit caller missing policy')
raw <- c(a='月薪3000', b='bad', c='bad', d='时薪20元')
check(identical(salary_example(factor(raw))$data, salary_example(unname(raw))$data), 'factor input')
check(identical(salary_example(raw)$review$index, c(2L,3L)), 'repeated failures')
for (input in list(1, list('3000'), matrix('月薪3000',1), NULL))
  check(bad(salary_example(input)), 'invalid input type')
for (period in list(NA_character_, c('month','year'), 'week', 1, matrix('month',1)))
  check(bad(salary_example('3000', context_period=period)), 'invalid period argument')
for (currency in list('', NA_character_, c('CNY','USD'), 1, matrix('CNY',1)))
  check(bad(salary_example('3000', currency=currency)), 'invalid currency argument')
check(bad(salary_example('3000', na=1)) && bad(salary_example('3000', na=matrix('NA',1))), 'invalid missing markers')

repeated <- rep(c('月薪3000','15K-25K/月 · 13薪','bad','面议',NA), 500L)
full <- salary_example(repeated)
parts <- lapply(split(seq_along(repeated), ceiling(seq_along(repeated)/137L)),
  function(rows) { z <- salary_example(repeated[rows])$data; z$index <- rows; z })
joined <- do.call(rbind, parts)
rownames(joined) <- NULL
check(identical(joined, full$data), 'chunk invariance')
check(identical(full$review$index, which(rep(c(FALSE,FALSE,TRUE,TRUE,FALSE),500L))), 'batch provenance')
grid <- expand.grid(coefficient=c(1,3,7), unit=c('元','千元','万','K'),
  period=c('hour','day','month','year'), wrapper=c('prefix','suffix','both'),
  payments=c(FALSE,TRUE), stringsAsFactors=FALSE)
prefix <- c(hour='时薪',day='日薪',month='月薪',year='年薪')[grid$period]
suffix <- c(hour='/小时',day='/天',month='/月',year='/年')[grid$period]
amount <- paste0(grid$coefficient,'-',grid$coefficient+2,grid$unit)
text <- paste0(ifelse(grid$wrapper=='suffix','',prefix),amount,
  ifelse(grid$wrapper=='prefix','',suffix),ifelse(grid$payments,'·13薪',''))
z <- salary_example(text)$data
accepted <- !grid$payments | grid$period=='month'
scale <- c('元'=1,'千元'=1000,'万'=10000,'K'=1000)[grid$unit]
check(identical(z$status,ifelse(accepted,'parsed','conditional')), 'generated wrapper/payment statuses')
check(identical(z$lower[accepted],unname((grid$coefficient*scale)[accepted])), 'generated independent lower')
check(identical(z$upper[accepted],unname(((grid$coefficient+2)*scale)[accepted])), 'generated independent upper')
check(all(z$lower_inclusive[accepted] & z$upper_inclusive[accepted]), 'generated closed inclusivity')
check(all(is.na(z$lower[!accepted])) && all(is.na(z$upper[!accepted])), 'generated conditional withholding')
check(identical(z$period,grid$period), 'generated period retention')
check(all(z$advertised_payments[grid$payments]==13L) &&
      all(is.na(z$advertised_payments[!grid$payments])), 'generated payment retention')
cat('PASS:',nrow(grid),'independent generated wrapper/unit/payment cases\n')
cat('PASS:', checks, 'salary example boundary/workflow checks\n')

cases <- read.csv('docs/fixtures/salary-source-cases.csv', colClasses='character',
  na.strings=character(), fileEncoding='UTF-8', check.names=FALSE)
numeric_or_na <- function(x) { x[x==''] <- NA_character_; as.double(x) }
for (i in seq_len(nrow(cases))) {
  row <- cases[i, ]
  z <- salary_example(row$input, context_period=if(row$context_period=='') NULL else row$context_period)
  check(identical(z$data$status, row$status), paste(row$id, 'source status'))
  check(identical(z$data$lower, numeric_or_na(row$lower)) &&
        identical(z$data$upper, numeric_or_na(row$upper)), paste(row$id, 'source amounts'))
  check(identical(z$data$period, if(row$period=='') NA_character_ else row$period), paste(row$id, 'source period'))
  check(identical(as.double(z$data$advertised_payments), numeric_or_na(row$advertised_payments)), paste(row$id, 'source declaration'))
}
cat('PASS:', nrow(cases), 'attributed source salary cases; cumulative checks:', checks, '\n')
