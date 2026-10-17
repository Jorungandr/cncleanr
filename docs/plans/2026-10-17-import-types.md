# Imported input types implementation plan

**Approved goal:** Respect SPSS user-defined missing values in all three parsers;
reject direct `units` parser input and require explicit unit conversion/removal.
No runtime dependencies, public arguments, C changes or general class adapter.

**Design:** One shared parser-entry function checks the two relevant classes.
For `haven_labelled_spss`, read `na_values`/`na_range` from the object, convert to
its plain numeric/character values, replace matching non-native-missing cells
with NA and retain names. Reading metadata directly must also work for objects
loaded from RDS without haven's namespace. Preserve pre-existing NA/NaN/tagged-NA
payloads when no header is applied. Units are rejected before any numeric cast,
including empty and dimensionless units; users explicitly choose the intended
unit, then call `units::drop_units()` themselves.

Alternative: silently drop units or require haven/units as runtime imports.
Rejected because the former loses meaning and the latter adds unnecessary
dependencies. Ordinary inputs only encounter constant-time class checks.

## Execution

Use writing-plans/Code in the existing checkout, no delegated agents. The user
authorized the design and the complete normal GitHub workflow, but not CRAN.

1. Add dependency-free metadata fixtures and units-class rejection regressions.
   Verify failures against installed 0.2.16, then implement shared preparation
   once and call it at all three validated parser entries.
2. Confirm real haven 2.5.5, units 1.0.1 and bit64 4.8.6 in task-local libraries:
   numeric/character discrete/range missingness, tags, labels, names, empty input,
   header scaling, strict diagnostics and explicit unit conversion/removal.
3. Repeat full tests, system/data audits and ordinary-input performance comparison.
   Preserve known double-precision limits; do not swallow third-party warnings.
4. Update bilingual README/Rd, NEWS and version 0.2.17. Build from clean committed
   source, check locally and on all five existing platform jobs. No C-tool rerun
   claim when C is unchanged.
5. Publish the checked archive at a fixed tag; public unauthenticated download,
   hash, isolated install and full recheck. Record actual evidence and limits.

## Completion

Steps 1–5 completed. Source commit: `1f5271cacb92c4a7261a5931a77e480c17d55c11`.
GitHub v0.2.17 is public; local check and all five CI jobs passed 1,008 assertions.
Real optional-package audits, public-download hash/install verification and
regression timing are recorded in [import-types.md](../import-types.md).
No runtime dependencies or C changes; no CRAN submission.
