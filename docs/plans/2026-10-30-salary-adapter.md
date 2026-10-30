# Independent salary example implementation plan

**Goal:** Implement the user-approved external salary adapter design without
changing the package's six exports, R/C production files or runtime dependencies.

**Architecture:** docs/salary-adapter.R defines salary_example(). Normalize only
documented characters and outer whitespace, peel anchored period/pay-count
wrappers, translate K/k within the salary field, and batch-call parse_cn_range.
Return independent data/review tables; never infer annual income or commission.

**Tech stack:** base R and installed cncleanr 0.2.25, existing CI and audit tools.

1. Create docs/salary-adapter-audit.R with independent supported/unsafe/empty,
   duplicated/labelled/factor, period-conflict, missing-marker and invalid-input
   expectations. Verify missing feature before implementation.
2. Add the example adapter; accept scalar explicit context_period/currency only,
   validate them, retain source index/raw, inclusivity and advertised payments.
   Nonparsed monetary fields stay NA. Zero/negative finite bounds require review.
3. Add attributed source-fragment cases from the preceding five-page assessment;
   keep context-dependent and synthetic cases distinct. Batch parsing once avoids
   a separate core parse for each row. Do not use private cncleanr symbols.
4. Execute local audit and a bounded cost check; do not restart general speed
   optimization. Verify existing exports/algorithms/tests remain unchanged.
5. Add Chinese/English usage guides, README links and literal-code validation.
   Run adapter tests on all five CI jobs, plus existing 1832 package assertions.
6. Push code and evidence together to GitHub main. This external example does
   not change the package version/tag/archive or submit CRAN.

The preceding assessment was accepted by the user's instruction to continue.
