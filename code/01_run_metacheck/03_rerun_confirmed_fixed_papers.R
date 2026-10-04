# Targeted rerun of exactly the papers confirmed, by direct testing against
# scienceverse/metacheck@dev (installed today, 2026-10-04, commit e4b74e1),
# to now be fixed by that commit -- NOT a full corpus rerun. These 50 papers
# were previously hand-audited (code/03_comparing_results/
# manual_repo_findability_audit.csv) as "Metacheck limitation" cases, and
# each one's specific mechanism (archive-expansion AND-logic bug, 5 missing
# extensions, or GROBID DOI whitespace) was individually re-verified against
# the live installed package before being added to this list -- see
# scratch_rerun_confirmed.csv for the full audit trail.
#
# Reuses the exact same module_run() call conventions (cache = TRUE,
# osf_license = TRUE, skip_on_api_limit = TRUE) and the same
# combine_batches()/strip_paper_text() helpers as
# 01_run_metacheck/01_run_metacheck.R, so the result is byte-for-byte
# equivalent in shape to what a full corpus rerun would have produced for
# these 50 papers -- only narrower in scope, to avoid re-touching 1811
# papers whose metacheck output has not changed.
#
# Usage (from inside code/): Rscript 01_run_metacheck/03_rerun_confirmed_fixed_papers.R

library(metacheck)
library(dplyr)

options(metacheck.cache.dir = "D:/")

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

status("metacheck version: %s", as.character(packageVersion("metacheck")))

strip_paper_text <- function(res) {
  res$paper <- NULL
  res
}

combine_batches <- function(batches) {
  all_fields <- unique(unlist(lapply(batches, names)))
  is_df <- function(x) is.data.frame(x)

  out <- list()
  for (f in all_fields) {
    vals <- lapply(batches, `[[`, f)
    vals <- vals[!vapply(vals, is.null, logical(1))]
    if (length(vals) == 0) next

    if (f %in% c("module", "title", "section")) {
      out[[f]] <- vals[[1]]
    } else if (f == "paper") {
      out[[f]] <- do.call(paperlist, vals)
    } else if (f == "previews") {
      out[[f]] <- do.call(c, vals)
    } else if (all(vapply(vals, is_df, logical(1)))) {
      nonempty <- vals[vapply(vals, nrow, integer(1)) > 0]
      out[[f]] <- if (length(nonempty) > 0) dplyr::bind_rows(nonempty) else vals[[1]]
    } else {
      out[[paste0(f, "_by_batch")]] <- vals
    }
  }
  out
}

# Remove every row belonging to `ids` from every paper_id-keyed data.frame
# field of a module_run() result, leaving non-data.frame and non-keyed
# fields (gated_repos, the _by_batch lists) untouched -- those are
# diagnostic/per-batch artifacts without per-paper row identity, and the
# same ambiguity already exists in the ordinary corpus-wide combine, so
# dropping old rows from them is neither necessary nor safe to do precisely.
drop_ids <- function(res, ids) {
  for (f in names(res)) {
    x <- res[[f]]
    if (is.data.frame(x) && "paper_id" %in% names(x)) {
      res[[f]] <- x[!(x$paper_id %in% ids), ]
    }
  }
  res
}

rerun_ids <- readLines("../scratch_rerun_article_ids.txt")
status("Rerunning %d confirmed-fixed papers.", length(rerun_ids))

status("Loading corpus (data/bes.rds)...")
bes <- readRDS("data/bes.rds")
stopifnot(all(rerun_ids %in% names(bes)))
target_papers <- bes[rerun_ids]

status("Running repo_check -> data_check -> code_check on the %d target papers...",
       length(rerun_ids))
res_repo_check_new <- module_run(target_papers, "repo_check", osf_license = TRUE, cache = TRUE)
res_data_check_new <- module_run(res_repo_check_new, "data_check", cache = TRUE, skip_on_api_limit = TRUE)
res_code_check_new <- module_run(res_data_check_new, "code_check", cache = TRUE, skip_on_api_limit = TRUE)

status("New results: repo_check %d rows, data_check %d rows, code_check %d rows (summary_table).",
       nrow(res_repo_check_new$summary_table), nrow(res_data_check_new$summary_table),
       nrow(res_code_check_new$summary_table))

# Save the raw new-only results first, before touching the corpus-wide
# files, so a crash/interruption during the merge step below never loses
# this (expensive, network-bound) rerun's output.
dir.create("01_run_metacheck/rerun_confirmed_fixed", showWarnings = FALSE)
save(res_repo_check_new, file = "01_run_metacheck/rerun_confirmed_fixed/res_repo_check_new.RData")
save(res_data_check_new, file = "01_run_metacheck/rerun_confirmed_fixed/res_data_check_new.RData")
save(res_code_check_new, file = "01_run_metacheck/rerun_confirmed_fixed/res_code_check_new.RData")
status("Saved raw rerun output to 01_run_metacheck/rerun_confirmed_fixed/.")

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

status("Dropping the %d target papers' OLD rows from the existing corpus-wide results...",
       length(rerun_ids))
res_repo_check_old_minus <- drop_ids(res_repo_check, rerun_ids)
res_data_check_old_minus <- drop_ids(res_data_check, rerun_ids)
res_code_check_old_minus <- drop_ids(res_code_check, rerun_ids)

status("Merging old-minus-50 with new-50 via the same combine_batches() logic the main pipeline uses...")
res_repo_check_merged <- combine_batches(list(res_repo_check_old_minus, res_repo_check_new))
res_data_check_merged <- combine_batches(list(res_data_check_old_minus, res_data_check_new))
res_code_check_merged <- combine_batches(list(res_code_check_old_minus, res_code_check_new))

stopifnot(nrow(res_repo_check_merged$summary_table) == nrow(res_repo_check$summary_table))
stopifnot(nrow(res_data_check_merged$summary_table) == nrow(res_data_check$summary_table))
stopifnot(nrow(res_code_check_merged$summary_table) == nrow(res_code_check$summary_table))
status("Row-count check passed: merged corpus-wide tables have the same total row count as before (%d/%d/%d).",
       nrow(res_repo_check_merged$summary_table), nrow(res_data_check_merged$summary_table),
       nrow(res_code_check_merged$summary_table))

# Back up the pre-rerun files before overwriting, same convention as the
# manual-audit merge scripts used earlier in this project.
dir.create("01_run_metacheck/backup_before_50paper_rerun", showWarnings = FALSE)
file.copy("01_run_metacheck/res_repo_check.RData",
          "01_run_metacheck/backup_before_50paper_rerun/res_repo_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_data_check.RData",
          "01_run_metacheck/backup_before_50paper_rerun/res_data_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_code_check.RData",
          "01_run_metacheck/backup_before_50paper_rerun/res_code_check.RData", overwrite = TRUE)
status("Backed up pre-rerun corpus-wide files to 01_run_metacheck/backup_before_50paper_rerun/.")

res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated with the 50 reran papers.")
status("Next: rerun 01_comparison_data.R, 03_build_master_comparison.R, and 02a/02b/02c, then re-render the manuscript.")
