# Salary field example adapter

[中文](salary-adapter-guide.md)

This independent GitHub repository example is not a seventh package export or
part of the installed package's docs directory. Obtain the repository, install
cncleanr 0.2.25 or the matching development version, and run from the repo root:

```r
source("docs/salary-adapter.R", local = TRUE, encoding = "UTF-8")
```

## Complete fields and separate review

```r
result <- salary_example(c("月薪3-5万元", "15-25K·13薪",
  "底薪5000+提成", "面议", NA_character_), currency = "CNY")
result$data
result$review
stopifnot(identical(result$data$status,
  c("parsed", "needs_context", "conditional", "negotiated", "missing")))
stopifnot(identical(result$review$index, 2:4))
```

The first row is 30000–50000 per month. The second lacks a pay period, so its
amounts remain missing while the advertised 13 payments are retained. Commission
conditions and negotiated pay need review; the genuinely missing row does not.
Use monetary values only where status is parsed and compare like periods and
currencies. Currency is a caller-supplied three-uppercase-letter source label,
not ISO validation or currency conversion. NULL does not infer CNY/TWD. Obvious
RMB/supplied-label conflicts are rejected.

## Explicit field context

```r
monthly <- salary_example("15-25K·13薪", context_period = "month", currency = "CNY")
stopifnot(monthly$data$lower == 15000, monthly$data$upper == 25000,
          monthly$data$advertised_payments == 13L, monthly$data$period == "month")
```

Supply context_period only when the source establishes hour/day/month/year.
Explicit text must agree with context and with any other period wrapper. Chinese
monthly/yearly/daily/hourly prefixes and corresponding slash suffixes are
supported. Weekly settlement text does not establish weekly pay and needs review.

N薪 requires a middle dot, asterisk or whitespace separator and a positive
representable integer N. No default 12 payments is supplied. Advertised payments
do not establish equal installments or guaranteed annual income. Combined
annual/daily/hourly bases and N-payment declarations require review.

K/k is translated to 1000 only inside this example, followed by a batched call
to parse_cn_range(). Point ranges, closed intervals and existing open inequalities
retain their inclusivity flags; no zero lower bound is invented. Listed dash and
full-width variants are normalized, but interdigit grouping still goes through
the core parser rather than arbitrarily joining digits.

Base-pay/commission/bonus/performance, tax, probation and similar conditions need
review. Unknown tails, W/M abbreviations, percentages and zero/negative amounts
do not produce usable salary values. This does not scan whole advertisements or
select their first number. Custom na markers match normalized complete original
fields; explicitly defining negotiated pay as missing overrides its review status.
Inputs must be character/factor vectors without dimensions; batch encoding errors
can still stop the call.

## Output and saving

The plain list contains data and review. Data retains index/raw, monetary bounds,
inclusivity, period, advertised_payments, currency and status. Review retains
index/raw/reason and duplicate rows. Nonparsed amounts and inclusivity are NA.
These tables are not original cncleanr results: do not pass them to cn_problems(),
cn_subset() or cn_summary(). Use review directly and maintain source indices when
reordering.

```r
write.csv(result$data, "salary-data.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(result$review, "salary-review.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
saveRDS(result, "salary-example.rds")
stopifnot(identical(readRDS("salary-example.rds"), result))
```

These commands overwrite named files in the current directory. CSV is not an
exact R-object backup; use your own RDS for original missingness, metadata and
binary precision. Sourcing the adapter alone only defines its function.

See the [assessment](salary-support-assessment-2026-10-30.md) and
[19-source-fragment notes](fixtures/salary-source-cases-README.md). Generated
boundaries and source cases are validated separately, not a market accuracy score.
