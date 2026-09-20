# Automating Data- and Code-Archiving Checks with Metacheck

This repository contains everything needed to **render the manuscript**
that validates [metacheck](https://github.com/scienceverse/metacheck)
against Cooper and the BES Data and Code Hackathon Group's (2026)
manually-coded corpus of 1861 BES-journal papers.

This is a standalone, minimal repository: it contains only the final
manuscript source, its bibliography/formatting files, and the small set
of saved results the manuscript reads. It does **not** contain the full
history of scripts, patches, and intermediate reruns behind those
results — that history lives in the original working repository
(`cooper_validation_metacheck`) and is documented in the manuscript's
own Appendix A.

## Render the manuscript

```bash
cd manuscript
quarto render manuscript.qmd
```

This needs no internet access and no corpus rerun — every number the
manuscript reports is read from the small `.RData`/`.csv` files already
in `manuscript/data/`.

`code_check_validation.qmd` (a separate, supporting validation report
referenced from the main manuscript's Appendix A.3) can be rendered the
same way, from `manuscript/data/validation/`.

## Reproducing the underlying analysis from scratch

If you want to rerun metacheck over the corpus yourself rather than
trust the saved results, see `manuscript/final_pipeline/README.md`. In
short:

1. You need `bes.rds` (the parsed 1861-paper corpus). It is not included
   here — it contains extracted full text of copyrighted journal
   articles. Contact the authors for access.
2. `Rscript manuscript/final_pipeline/01_run_metacheck.R` runs
   metacheck's `repo_check`/`data_check`/`code_check` modules over the
   whole corpus.
3. `Rscript manuscript/final_pipeline/02_build_comparison_data.R` derives
   the comparison columns, builds the disagreement worklist, and
   computes the statistics the manuscript reports.
4. The disagreement worklist then needs a human (or an LLM assistant
   working the same way) to review each flagged disagreement — this step
   is manual, not automated, and is where most of the analytical work in
   this project actually happened. See `final_pipeline/README.md` for
   the evidence-source rule each column should be checked against.

## Structure

```text
manuscript/
├── manuscript.qmd                 # the manuscript itself
├── code_check_validation.qmd      # supporting validation report (Appendix A.3)
├── references.bib, package-citations.bib, apa.csl, style.css, _quarto.yml
├── _extensions/                   # apaquarto Quarto extension
├── final_pipeline/                # the fastest reproducible path to the manuscript's numbers
│   ├── 01_run_metacheck.R
│   ├── 02_build_comparison_data.R
│   ├── helpers.R
│   └── README.md
└── data/
    ├── res_repo_check.RData       # metacheck's repo_check output, full corpus
    ├── res_data_check.RData       # metacheck's data_check output, full corpus (Git LFS)
    ├── res_code_check.RData       # metacheck's code_check output, full corpus (Git LFS)
    ├── recreated_cooper_columns.RData
    ├── cooper_vs_recreated.RData / .xlsx
    ├── comparison_statistics.RData
    ├── disagreement_cause_categories.RData
    ├── disagreement_review_worklist.csv / .xlsx  # the manually-reviewed disagreement worklist
    ├── repo_not_detected_categorization.csv
    ├── comment_quality_correlation.RData
    ├── free_extras_summary.RData
    ├── rerun_disagreements_comparison.csv
    ├── bes_crossref.RData          # CrossRef bibliographic metadata (not copyrighted)
    ├── manifests/                  # per-paper provenance JSON
    └── validation/                 # evidence base for code_check_validation.qmd
```

`res_data_check.RData` and `res_code_check.RData` are stored via
[Git LFS](https://git-lfs.com) (each is ~1.4GB); install `git-lfs` before
cloning if you want them, or clone with `GIT_LFS_SKIP_SMUDGE=1` if you
only want the manuscript source.

## Citation

See the manuscript itself for the full citation and Cooper et al.'s
(2026) original corpus and coding protocol.
