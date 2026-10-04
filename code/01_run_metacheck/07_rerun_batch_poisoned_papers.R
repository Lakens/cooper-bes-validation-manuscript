# Targeted rerun of the 3 papers confirmed to still genuinely show files_n=0
# due to the Dataverse/Figshare/DataONE/4TU batch-error-isolation gap
# (reported upstream as scienceverse/metacheck#460): all three cite a
# Figshare COLLECTION DOI (m9.figshare.c.*), and their gated_repos entry
# carries the stale "arguments imply differing number of rows" error from
# an earlier run. Of 200 total poisoned gated_repos rows, 197 already
# self-corrected in a later run (their files are already present in the
# current corpus-wide data); these 3 are the only ones that did not.
# Confirmed live and uncached: re-querying figshare_info() for all 3
# collection DOIs succeeds with no error.
#
# Usage (from inside code/): Rscript 01_run_metacheck/07_rerun_batch_poisoned_papers.R

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

rerun_ids <- c(
  "10_1111_1365_2664_14575",
  "10_1111_1365_2745_13725",
  "10_1111_1365_2745_13728"
)
status("Rerunning %d papers uncached: %s", length(rerun_ids), paste(rerun_ids, collapse = ", "))

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
print(res_repo_check_new$summary_table)

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

status("Dropping the old rows for these %d papers from the existing corpus-wide results...", length(rerun_ids))
res_repo_check_old_minus <- drop_ids(res_repo_check, rerun_ids)
res_data_check_old_minus <- drop_ids(res_data_check, rerun_ids)
res_code_check_old_minus <- drop_ids(res_code_check, rerun_ids)

status("Merging old-minus-3 with new-3...")
res_repo_check_merged <- combine_batches(list(res_repo_check_old_minus, res_repo_check_new))
res_data_check_merged <- combine_batches(list(res_data_check_old_minus, res_data_check_new))
res_code_check_merged <- combine_batches(list(res_code_check_old_minus, res_code_check_new))

stopifnot(nrow(res_repo_check_merged$summary_table) == nrow(res_repo_check$summary_table))
stopifnot(nrow(res_data_check_merged$summary_table) == nrow(res_data_check$summary_table))
stopifnot(nrow(res_code_check_merged$summary_table) == nrow(res_code_check$summary_table))
status("Row-count check passed: %d/%d/%d.",
       nrow(res_repo_check_merged$summary_table), nrow(res_data_check_merged$summary_table),
       nrow(res_code_check_merged$summary_table))

dir.create("01_run_metacheck/backup_before_batch_poisoned_rerun", showWarnings = FALSE)
file.copy("01_run_metacheck/res_repo_check.RData",
          "01_run_metacheck/backup_before_batch_poisoned_rerun/res_repo_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_data_check.RData",
          "01_run_metacheck/backup_before_batch_poisoned_rerun/res_data_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_code_check.RData",
          "01_run_metacheck/backup_before_batch_poisoned_rerun/res_code_check.RData", overwrite = TRUE)
status("Backed up pre-rerun corpus-wide files.")

res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated.")
