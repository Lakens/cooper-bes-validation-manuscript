# Final data-sharing pipeline

This folder is **not** a history of how the numbers in the manuscript
were arrived at — that history (every intermediate script, patch, and
rebuild) lives in `../code_data_preparation/` and is documented in the
manuscript's Appendix A. This folder is the shortest path from a built
corpus to the same files the manuscript reads, for someone who wants to
reproduce or rerun the analysis, not relive its history.

## Prerequisite

`data/bes.rds` — the corpus of 1861 parsed papers — must already exist.
It is built separately by `build.R` at the repository root (downloads
each paper's PDF via Europe PMC or an institutional proxy login, then
converts it with GROBID). That step is not part of this folder: it is
slow (hours), requires credentials this folder does not need, and is
already documented in the repository root's own `README.md`.

`../sample.csv` (also produced by `build.R`) must exist alongside it.

## Steps

Run these in order, from inside `manuscript/` (not from inside this
folder):

```
Rscript final_pipeline/01_run_metacheck.R
Rscript final_pipeline/02_build_comparison_data.R
```

**Step 1** (`01_run_metacheck.R`) runs metacheck's `repo_check`,
`data_check`, and `code_check` modules over the whole corpus and saves
the combined result as `data/res_repo_check.RData`,
`data/res_data_check.RData`, `data/res_code_check.RData`. This is the
slow step (network calls to every repository platform cited in the
corpus) and is resumable — batches already written to `data/batches/`
are reused if the script is stopped and rerun.

**Step 2** (`02_build_comparison_data.R`) derives Metacheck's `mc_`-prefixed
columns from that output, joins them against Cooper et al.'s own coded
ground truth, computes the agreement/sensitivity/specificity statistics
the manuscript's Empirical Comparison section reports, and writes a
**blank** disagreement worklist — one row per paper with at least one
column disagreement, with the disagreement itself named, but with every
`_verdict`/`_comment` cell empty.

## What happens after Step 2 is manual, not code

The worklist at `data/disagreement_review_worklist.csv` is the point
where automation stops. Every disagreement in it needs a human (or an
LLM assistant working the same way, one paper at a time) to open the
paper's own text and Metacheck's saved output, decide which side was
right and why, and fill in that row's `_verdict` (one of `COOPER_RIGHT`,
`METACHECK_RIGHT`, `BOTH_DEFENSIBLE`, `DIFFERENT_DEFINITION`, or
`UNCLEAR`) and `_comment` (the evidence for that call). Nothing in this
folder does that step, and nothing should — see the manuscript's own
Empirical Comparison section for the exact evidence-source rule each
column should be checked against.

Once every disagreement has a verdict, rerun `02_build_comparison_data.R`
(it recomputes the comparison statistics from whatever verdicts are
present each time) so `data/comparison_statistics.RData` reflects the
completed review, then render `../manuscript.qmd`.
