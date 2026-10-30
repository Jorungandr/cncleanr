# Literal bilingual tutorial checks

**Goal:** Verify copied tutorial code automatically on all five existing CI jobs.

Extend the existing docs/readme-audit.R entry point to execute literal R fences
from the Chinese/English financial-table and business tutorials. Do not introduce
a second documentation execution framework or a new package dependency.

Each tutorial gets its own temporary directory/environment. Installation fences
are counted but not executed; unexpected warnings/errors fail. Financial-table
assertions run unchanged, then exported original text, source rows, units,
numerical results and review reasons are checked. Business import examples read
the existing 22-case attributed offline fixture in the documented relative path;
this does not claim that the full real snapshots run in CI.

Keep existing README results separate (14 runnable blocks per edition) and
report each tutorial's actual runnable/install block count. Verify locally with
installed v0.2.25 and on GitHub's five-platform workflow. Update bilingual README
coverage and evidence. No runtime parser, API, version, release asset or CRAN
change is planned.
