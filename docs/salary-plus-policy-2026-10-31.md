# Salary trailing-plus policy validation

Source: 29c16240af52ad090d07a52ea569d60b05f61cea.

The independent salary example now withholds monetary bounds and requires
conditional review for a trailing bare plus. Explicit 以上 remains an open lower
bound. This applies after period/payment wrappers are removed, including
full-width plus signs. Ordinary parse_cn_range("10万+") remains unchanged.

Five new assertions cover plain/full-width plus, period suffixes, range amounts,
payment declarations, review positions and preservation of the core policy.
Local salary audit: 133 assertions passed, including 19 source cases and the
existing 288 generated combinations. Bilingual README/tutorial code checks passed.

GitHub run 41211236845 completed all five jobs successfully: Ubuntu oldrel-1
124566499666, Ubuntu devel 124566499748, Ubuntu release 124566499762,
Windows release 124566499840 and macOS release 124566499884. Downloaded Ubuntu
logs confirm 133 salary audit assertions, 1832 package assertions, Status OK
and PDF manual OK. The macOS conclusion was confirmed through the job API.

Earlier network failures delayed synchronization; the exact source commit is
now on GitHub. This final evidence-only document does not alter tested code.
Package version remains 0.2.25; no R/src/NAMESPACE/DESCRIPTION changes, new
tag, replacement release archive, speed claim or CRAN submission.
