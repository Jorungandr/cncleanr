# Salary expression facts used by the example audit

Nineteen manually selected expressions/fragments, observed 2026-10-30; not a
random dataset or a claim that these jobs are still available. Monetary facts
and short expressions only, no contact details, resumes or full advertisements.
No open-data license is asserted for the commercial pages. Keep source links.
The fixture is an assessment-derived selection, not an archived full-page scrape.

* visionstar: https://www.visionstar.cn/recruitment?page=12
* dujiao: https://www.dujiao.net/job?page=3&title=%E6%96%87%E6%A1%88
* bnu: https://hr.bnu.edu.cn/rczp/rczpxx/985gcry/985dytj/60524.htm
* xunwu: https://www.xunwu.gov.cn/xwxxxgk/rsjycy/202606/c109ede3fa994645b0c5000e464a47b0.shtml
* mmpt: https://www.mmpt.edu.cn/__local/C/32/F5/B2244EE45E3D4C49D467013CE8B_86C58AC0_2BC45.pdf

S11/S12 are amount fragments: their year context comes from the source paragraph,
not text inferred by the adapter. Other expressions retain relevant condition
text. Outer/interword typography is transcribed to ordinary spaces; numeric
digits are not repaired or extracted from malformed larger expressions.
Expected statuses are nine parsed, five needs_context, four conditional and one
negotiated. Blank expected monetary fields mean NA, not zero. Currency stays
unspecified; no annual income is computed. See the assessment for design limits.
