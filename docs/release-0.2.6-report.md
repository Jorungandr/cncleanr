# 0.2.6 release acceptance

Date: 2026-10-03 (Asia/Shanghai).

- Parser commit `30ce4c92abd8fdbd8d729aed130c675e054af406`: all five
  cross-platform jobs passed, including Linux PDF manual generation.
  [CI](https://github.com/Jorungandr/cncleanr/actions/runs/36892910430).
- Full testthat suite: 190 passing assertions. Existing CFQA audit retains
  1,412 correct valid spans and six rejected malformed spans.
- Built the source archive and installed it into a separate local library.
  `docs/release-0.2.6-check.R` passed against that installed package: 18 actual
  monetary cells, separate EPS/ratio handling, conflict reporting, README
  example, installed help, and installed number-parser examples.
- Real table: [Suning 2019 annual report](https://www.suning.cn/static/snsite/contentresource/2020-04-20/d4ce9420-8511-4ada-ac1a-7578761392c7.PDF),
  printed page 6, six monetary rows across 2019/2018/2017. Header is thousand
  yuan, but EPS explicitly uses yuan/share and ROE uses percentages.
  PDF SHA256: `783BA4E87BE798553CE20E23160057439D4127C6E434C9A7037BB22ED74653F1`.
  Source PDF was visually inspected; it remains local and is not redistributed.
  This is a publicly disclosed report, not a claim of an open-data license.
- Both READMEs now distinguish GitHub 0.2.6 from CRAN 0.2.5 and explain
  mixed-unit tables. Historical CRAN submission records remain unchanged.
- Publish GitHub only. No CRAN resubmission in this workflow.

Reproduce after building `cncleanr_0.2.6.tar.gz`:

```text
R CMD INSTALL --library=outputs/release-0.2.6/library cncleanr_0.2.6.tar.gz
Rscript --vanilla docs/release-0.2.6-check.R outputs/release-0.2.6/library
```

Create the library directory first. These checks cover selected cells, not
automatic PDF extraction, header inference, or every possible table layout.
