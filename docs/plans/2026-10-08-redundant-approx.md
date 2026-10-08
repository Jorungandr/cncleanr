# Redundant approximation design and implementation plan

Approved scope: accept one supported approximation prefix plus the suffix
左右, retaining `approx`. Strip each once through the existing shared quantity
parser. Do not allow repeated prefixes, nested suffixes, mixed inequalities,
or plus/minus statistics. Range parsing continues to reject approximations.

Reuse the shared parser rather than preprocessing each caller or adding a
general qualifier-merging abstraction. Add regression cases, update bilingual
docs, run the full suite and CSL case, and retry the pending GitHub push.
Record this as 0.2.7 development work; do not alter release tags or submit CRAN.
