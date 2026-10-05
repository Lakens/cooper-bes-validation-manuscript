# The comparison/manuscript pipeline, declared as a dependency graph.
#
# SCOPE: this covers only the fast, deterministic chain from
# res_*_check.RData through to the manuscript PDF. The multi-hour,
# rate-limited, live-API corpus run (code/01_run_metacheck/01_run_metacheck.R)
# and the targeted rerun-and-merge scripts (code/01_run_metacheck/03_*.R
# through 07_*.R) stay OUTSIDE this pipeline, run manually exactly as
# before -- targets only watches the three files they produce
# (res_repo_check.RData, res_data_check.RData, res_code_check.RData) for
# changes and rebuilds everything downstream of whichever one changed.
#
# Usage: Rscript -e "targets::tar_make()"            # bring everything up to date
#        Rscript -e "targets::tar_visnetwork()"       # see the dependency graph
#        Rscript -e "targets::tar_outdated()"         # see what's stale, without running anything
#        Rscript -e "targets::tar_read(master_comparison)"  # inspect one target's value

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("dplyr", "metacheck", "openxlsx"),
  # Drop a target's value from memory as soon as its dependents are
  # built, and force a gc() afterward -- replaces the original pipeline's
  # pattern of running the ~1.9GB res_data_check.RData / res_code_check.RData
  # loads in their own fresh Rscript processes just so the OS would
  # reclaim the memory between steps.
  memory = "transient",
  garbage_collection = TRUE,
  format = "rds"
)

# code/R/* function files, converted from the original numbered scripts.
tar_source("R")

list(
  # == Tier-0 inputs: files produced OUTSIDE this pipeline ===========================
  # The heavy corpus run and the targeted rerun-and-merge scripts write
  # these three files directly; targets only watches their content hash.
  tar_target(res_repo_check_file, "code/01_run_metacheck/res_repo_check.RData", format = "file"),
  tar_target(res_data_check_file, "code/01_run_metacheck/res_data_check.RData", format = "file"),
  tar_target(res_code_check_file, "code/01_run_metacheck/res_code_check.RData", format = "file"),
  tar_target(res_open_practices_file, "code/01_run_metacheck/res_open_practices.RData", format = "file"),
  tar_target(res_oddpub_file, "code/01_run_metacheck/res_oddpub.RData", format = "file"),

  # Human-edited inputs, tracked for changes but never regenerated here.
  tar_target(cooper_csv_file, "code/02_create_comparison_data/BES-data-code-hackathon-cleaned_2025-12-01.csv", format = "file"),
  tar_target(sample_csv_file, "code/02_create_comparison_data/sample.csv", format = "file"),
  tar_target(manual_repo_findability_audit_csv, "code/03_comparing_results/manual_repo_findability_audit.csv", format = "file"),
  tar_target(manual_fair_api_findability_audit_csv, "code/03_comparing_results/manual_fair_api_findability_audit.csv", format = "file"),
  tar_target(repo_not_detected_categorization_csv, "code/03_comparing_results/repo_not_detected_categorization.csv", format = "file"),

  # == Slim extraction chain (02a/02b/02c) ============================================
  tar_target(structure_slim_obj, extract_structure_slim(res_data_check_file)),
  tar_target(code_table_slim_obj, extract_code_table_slim(res_code_check_file)),
  tar_target(manuscript_data_slim, assemble_manuscript_data_slim(
    res_repo_check_file, structure_slim_obj, code_table_slim_obj)),

  # == Comparison data (01_comparison_data.R) =========================================
  tar_target(recreated_cooper_columns, recreate_cooper_columns(
    res_repo_check_file, res_data_check_file, res_code_check_file)),
  tar_target(cooper_vs_metacheck, build_cooper_vs_metacheck(
    recreated_cooper_columns, cooper_csv_file, sample_csv_file)),

  # == Disagreement worklist (02_build_disagreement_worklist.R) ======================
  # The xlsx is both an upstream INPUT (format = "file", so a hand edit
  # to a verdict/comment cell -- made between tar_make() runs, outside
  # targets entirely -- changes this target's hash and correctly
  # re-triggers disagreement_worklist below) and, via a separate output
  # target further down, something this pipeline also writes back to.
  # Confirmed directly this split is necessary: with only one target for
  # both directions, a hand-edited verdict was silently discarded on the
  # next tar_make(), because the write step ran from a stale cached
  # disagreement_worklist value that pre-dated the hand edit.
  tar_target(disagreement_worklist_xlsx_input,
             "code/02_create_comparison_data/disagreement_review_worklist.xlsx",
             format = "file"),
  tar_target(disagreement_worklist, build_disagreement_worklist(
    cooper_vs_metacheck, disagreement_worklist_xlsx_input, "disagreement_worklist")),
  tar_target(disagreement_worklist_xlsx_written,
             write_disagreement_worklist_xlsx(disagreement_worklist, disagreement_worklist_xlsx_input),
             format = "file"),

  # == Master comparison (03_build_master_comparison.R) ==============================
  tar_target(master_comparison, build_master_comparison(
    cooper_vs_metacheck, res_open_practices_file, res_oddpub_file,
    cooper_csv_file, sample_csv_file)),

  # == Statistics and summaries read directly by manuscript.qmd ======================
  tar_target(comparison_statistics, compute_comparison_statistics(
    master_comparison, disagreement_worklist$review)),
  tar_target(disagreement_cause_categories, categorize_disagreement_causes(
    disagreement_worklist$review)),
  tar_target(comment_quality_correlation, compute_comment_quality_correlation(
    res_code_check_file, cooper_csv_file, sample_csv_file)),
  tar_target(free_extras_summary, summarize_free_extras(
    res_repo_check_file, res_data_check_file, res_code_check_file)),
  tar_target(data_archive_uncoded_papers, summarize_data_archive_uncoded_papers(
    master_comparison, res_data_check_file)),

  # == Manuscript render ===============================================================
  # manuscript.qmd itself must be a tracked file target: targets only
  # watches a target's OWN command code for changes, not the content of
  # a file that command happens to call (quarto::quarto_render() takes a
  # fixed path, so editing manuscript.qmd's prose/chunks does not change
  # the manuscript_render target's command and would otherwise never be
  # detected as outdated). Confirmed directly: without this, editing
  # manuscript.qmd and rerunning tar_make() left manuscript_render
  # "skipped" rather than rebuilt.
  tar_target(manuscript_qmd_file, "manuscript.qmd", format = "file"),

  tar_target(
    manuscript_render,
    {
      # Force a dependency on every target manuscript.qmd reads via
      # tar_read()/tar_load(), so this target (and therefore the PDF) is
      # recognized as outdated whenever any of them change -- listing
      # them here as a no-op reference is enough for targets' static
      # dependency detection, since manuscript.qmd itself calls tar_read()
      # by name rather than taking these as function arguments.
      force(manuscript_qmd_file)
      force(manuscript_data_slim); force(master_comparison)
      force(comparison_statistics); force(disagreement_cause_categories)
      force(comment_quality_correlation); force(free_extras_summary)
      force(data_archive_uncoded_papers); force(disagreement_worklist)
      force(manual_repo_findability_audit_csv)
      force(manual_fair_api_findability_audit_csv)
      force(repo_not_detected_categorization_csv)
      quarto::quarto_render("manuscript.qmd")
      "output/manuscript/manuscript.pdf"
    },
    format = "file"
  )
)
