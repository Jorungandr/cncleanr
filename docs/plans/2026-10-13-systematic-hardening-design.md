# Systematic hardening design

Approved scope: repair the six reproduced audit defects together, then make
current data audits and release validation reproducible. Keep one R package,
the registered native fast path, existing public signatures and uncertain
semantics (qualified missing markers, matrix flattening, accounting-unit
propagation). No CRAN upload is authorized.

Use narrow shared validation rather than a parser rewrite. Reject percentage
versus non-percentage range endpoints after suffix propagation; retain compatible
magnitude ranges. Preserve original names before factor conversion. Rescue
extreme decimal scaling in the R fallback, with native boundary inputs deferred
to it, and report nonzero values that underflow after final conversion.
Correct endpoint-specific diagnostics and cap separator candidates to bound
malformed-input work. Ordinary cases retain their existing conversion path.

Independent literal-answer regressions precede fixes. Verify development tests,
dependency-free checks, source installation and R CMD check. Publish GitHub
only after verification, then confirm cross-platform CI and the release asset.
