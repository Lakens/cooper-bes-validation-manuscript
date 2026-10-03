# Comparison statistics and qualitative categorization

This folder computes the statistics and categorizations `manuscript.qmd`'s
Empirical Comparison section and Appendix A read at render time. It
depends on `02_create_comparison_data/`'s output, not on `manuscript/data/`.

## Scripts

Run these in order, from inside `manuscript/`:

```
Rscript 03_comparing_results/01_compute_comparison_statistics.R
Rscript 03_comparing_results/02_categorize_disagreement_causes.R
```

**`01_compute_comparison_statistics.R`** reads
`02_create_comparison_data/master_comparison.rds` (the full 1861-paper
corpus, agreements included) and
`02_create_comparison_data/disagreement_review_worklist.xlsx` (the
individually-verified `_verdict`/`_comment` columns), and computes, for
every comparison column, the confusion table, sensitivity/specificity,
McNemar's test, and the two directional miss rates. Saves
`comparison_statistics.RData` (`results`, `verdict_tallies`).

**`02_categorize_disagreement_causes.R`** reads the same worklist xlsx
and categorizes each reviewed disagreement's verdict comment into a
small, reproducible set of root-cause buckets by keyword pattern, so the
manuscript's qualitative "N of M disagreements were caused by X" prose is
computed from the actual review comments, not hand-counted. Saves
`disagreement_cause_categories.RData` (`cooper_right_causes`,
`any_readme_dd_causes`, `data_availability_dd_causes`,
`code_archived_mr_causes`).

## `repo_not_detected_categorization.csv` — a manual input, not a script's output

Unlike everything else in this folder, `repo_not_detected_categorization.csv`
is not produced by any script here or upstream — it is itself the primary
record of a manual review, the same way the worklist xlsx's
`_verdict`/`_comment` columns are. It categorizes every paper still
showing a "repository not detected" disagreement after every fix and
corpus rerun documented in Appendix A, by root cause, determined by
reading the paper's own extracted text and, where relevant, querying the
cited repository platform's own API directly. `manuscript.qmd`'s
`a6-categorization-load` chunk reads it as-is to build Table 1 ("Reasons
why Metacheck Misses an Existing Repository"). If the underlying corpus
or disagreement set changes, this file needs a fresh manual review pass,
not a rerun of code.

## `manual_repo_findability_audit.csv` and `manual_fair_api_findability_audit.csv` — manual inputs, not a script's output

Two further manual inputs, covering a differently-defined population
from `repo_not_detected_categorization.csv` above: every paper where
Cooper et al.'s own coders recorded a repository link but Metacheck's
`data_availability` judgement disagreed (213 papers; overlaps with but is
not identical to, and has not been cross-reconciled against, the
population above). Both were built from the same earlier spreadsheet
(`BES_metacheck_missed_repos_FAIR_audit.xlsx`, `coder_found_repo ==
TRUE` rows), reviewed in two separate passes, and are read as-is by
`manuscript.qmd`:

- **`manual_repo_findability_audit.csv`** (`manual-findability-audit-load`
  chunk, builds Table 1b): for each paper, whether Metacheck specifically
  could have found the cited repository, classified into one of seven
  root-cause categories (already correctly detected, a fixable
  platform-configuration or extraction gap, a genuine Metacheck-side bug,
  a platform Metacheck has no backend for at all, or a repository that is
  not actually live/accessible).
- **`manual_fair_api_findability_audit.csv`** (`fair-api-findability-load`
  chunk): a separate, later, stricter pass over the same 213 papers,
  asking whether the cited repository is machine-findable *in principle*
  by any suitably platform-aware automated tool — a real persistent
  identifier, a documented machine-queryable API, and live public
  accessibility, independent of whether Metacheck itself supports that
  platform.

Unlike `repo_not_detected_categorization.csv` (reviewed directly by the
manuscript's author), both of these were reviewed by one independent AI
agent (Claude, Anthropic) per paper — stated explicitly in the
manuscript text because this is a different review method from every
other classification in the manuscript, and carries a different,
currently less well-characterised error profile. Three of the 213
papers in `manual_repo_findability_audit.csv` were instead checked
directly by the author, as a manual pilot before the agent-based pass;
no paper in either file was reviewed by a human afterward. If the
underlying corpus or disagreement set changes, both files need a fresh
review pass (manual or agent-based), not a rerun of code.
