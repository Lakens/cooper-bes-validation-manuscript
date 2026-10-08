# Targeted rerun of the 5 papers manually audited as FILES_NOT_ENUMERATED
# (code/03_comparing_results/manual_repo_findability_audit.csv): their
# cached res_data_check.RData file counts (biomonitoR=9, tRophicPosition=11,
# actel=7, RevGadgets=13, frair=5) were all produced by a shallow,
# non-recursive GitHub crawl that never descended into subdirectories. The
# fix (github_tree_files() rewritten to list every file in the repository,
# like every other archive source) landed in commit da402e1 on 2026-08-13 --
# well before the audit rows were even written (2026-10-04) -- so the
# cached corpus-wide results predate a fix that was already live when the
# audit happened; a live GitHub API check against each repo (done directly
# against github_tree_files() at the installed package's commit, 80a7d37e)
# confirmed full recursive trees of 60-332 files, including every R/ source
# file, for all 5.
#
# Reuses the exact same module_run() call conventions (cache = FALSE, since
# the existing cache entries predate the fix and would just return the old
# shallow listing) and the same combine_batches()/drop_ids() helpers as
# every prior targeted rerun in this directory.
#
# Usage (from inside code/): Rscript 01_run_metacheck/10_rerun_files_not_enumerated.R

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

drop_ids <- function(res, ids) {
  for (f in names(res)) {
    x <- res[[f]]
    if (is.data.frame(x) && "paper_id" %in% names(x)) {
      res[[f]] <- x[!(x$paper_id %in% ids), ]
    }
  }
  res
}

# The 5 article_ids audited as FILES_NOT_ENUMERATED:
#   10_1111_1365_2664_13795  biomonitoR
#   10_1111_2041_210x_13009  tRophicPosition
#   10_1111_2041_210x_13503  actel
#   10_1111_2041_210x_13750  RevGadgets
#   10_1111_2041_210x_12784  frair
rerun_ids <- c(
  "10_1111_1365_2664_13795",
  "10_1111_2041_210x_13009",
  "10_1111_2041_210x_13503",
  "10_1111_2041_210x_13750",
  "10_1111_2041_210x_12784"
)
status("Rerunning %d papers (FILES_NOT_ENUMERATED, cache = FALSE): %s",
       length(rerun_ids), paste(rerun_ids, collapse = ", "))

status("Loading corpus (data/bes.rds)...")
bes <- readRDS("data/bes.rds")
stopifnot(all(rerun_ids %in% names(bes)))
target_papers <- bes[rerun_ids]

status("Running repo_check -> data_check -> code_check (cache = FALSE)...")
res_repo_check_new <- module_run(target_papers, "repo_check", osf_license = TRUE, cache = FALSE)
res_data_check_new <- module_run(res_repo_check_new, "data_check", cache = FALSE, skip_on_api_limit = TRUE)
res_code_check_new <- module_run(res_data_check_new, "code_check", cache = FALSE, skip_on_api_limit = TRUE)

status("New results: repo_check %d rows, data_check %d rows, code_check %d rows (summary_table).",
       nrow(res_repo_check_new$summary_table), nrow(res_data_check_new$summary_table),
       nrow(res_code_check_new$summary_table))
print(res_data_check_new$summary_table[, c("paper_id", "repo_n", "files_n", "files_data", "files_code", "files_readme")])

dir.create("01_run_metacheck/rerun_files_not_enumerated", showWarnings = FALSE)
save(res_repo_check_new, file = "01_run_metacheck/rerun_files_not_enumerated/res_repo_check_new.RData")
save(res_data_check_new, file = "01_run_metacheck/rerun_files_not_enumerated/res_data_check_new.RData")
save(res_code_check_new, file = "01_run_metacheck/rerun_files_not_enumerated/res_code_check_new.RData")
status("Saved raw rerun output to 01_run_metacheck/rerun_files_not_enumerated/.")

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

status("Dropping the %d target papers' OLD rows from the existing corpus-wide results...",
       length(rerun_ids))
res_repo_check_old_minus <- drop_ids(res_repo_check, rerun_ids)
res_data_check_old_minus <- drop_ids(res_data_check, rerun_ids)
res_code_check_old_minus <- drop_ids(res_code_check, rerun_ids)

status("Merging old-minus-5 with new-5 via the same combine_batches() logic the main pipeline uses...")
res_repo_check_merged <- combine_batches(list(res_repo_check_old_minus, res_repo_check_new))
res_data_check_merged <- combine_batches(list(res_data_check_old_minus, res_data_check_new))
res_code_check_merged <- combine_batches(list(res_code_check_old_minus, res_code_check_new))

stopifnot(nrow(res_repo_check_merged$summary_table) == nrow(res_repo_check$summary_table))
stopifnot(nrow(res_data_check_merged$summary_table) == nrow(res_data_check$summary_table))
stopifnot(nrow(res_code_check_merged$summary_table) == nrow(res_code_check$summary_table))
status("Row-count check passed: merged corpus-wide tables have the same total row count as before (%d/%d/%d).",
       nrow(res_repo_check_merged$summary_table), nrow(res_data_check_merged$summary_table),
       nrow(res_code_check_merged$summary_table))

# No full-copy backup step here (unlike earlier rerun scripts): the C:
# drive has limited free space (~19GB) and res_data_check.RData/
# res_code_check.RData alone are ~1.9GB each, so a redundant backup copy
# risks the same "No space left on device" failure this script hit on its
# first attempt. The merged-old-minus-5-plus-new-5 objects already in
# memory (res_*_check_merged) are the only copy of the update; if the
# save() calls below fail partway, rerun this script again from the
# original (unmodified) res_*_check.RData files -- they are not touched
# until all three save() calls below run.
status("Skipping backup copy step (limited disk space) -- writing directly.")

res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated with the 5 reran papers.")
status("Next: run targets::tar_make() from the project root to rebuild the comparison data, disagreement worklist, and manuscript.")
