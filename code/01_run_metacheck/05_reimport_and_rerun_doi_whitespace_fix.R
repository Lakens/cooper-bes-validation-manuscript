# Round 2b: the 10 papers from scratch_rerun_round2_ids.txt, confirmed by
# issue #458's analysis to be resolved by the merged DOI-whitespace fix --
# but that fix only runs at PDF->GROBID->TEI->paper-object IMPORT time
# (inside .process_full_text(), called from .tei_text() <- .grobid_to_bibr()).
# It never re-applies to text already cached in the existing bes.rds paper
# objects, so round 2's rerun (04_rerun_doi_whitespace_fix_papers.R), which
# reused the OLD paper objects from bes.rds, achieved zero real improvement
# (confirmed directly: paper 10_1002_2688_8319_12315's live text in bes.rds
# still read "zenodo. org/ record/8347003" after that rerun).
#
# This script instead re-imports all 10 papers from their raw PDFs
# (D:/pdf/<article_id>.pdf) through convert_grobid() -> grobid_to_bibr(),
# confirmed by direct test (scratch_test_grobid_reimport.R) to produce a
# fresh scivrs_paper object with the corrected, whitespace-collapsed text
# (verified: "https://zenodo.org/record/8347003" with no internal spaces).
# The fresh paper objects are substituted into bes.rds for just these 10
# IDs (bes.rds itself is updated, since it is the authoritative corpus
# paperlist used by the full pipeline), then repo_check/data_check/code_check
# are rerun on them, and the results merged into the corpus-wide
# res_*_check.RData files using the same combine_batches()/drop_ids()
# pattern as rounds 1 and 2 (03_rerun_confirmed_fixed_papers.R,
# 04_rerun_doi_whitespace_fix_papers.R).
#
# Usage (from inside code/): Rscript 01_run_metacheck/05_reimport_and_rerun_doi_whitespace_fix.R

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

rerun_ids <- readLines("../scratch_rerun_round2_ids.txt")
rerun_ids <- rerun_ids[nzchar(rerun_ids)]
status("Re-importing %d papers from PDF via GROBID (issue #458 fix).", length(rerun_ids))

xml_dir <- "D:/grobid_reimport_round2"
dir.create(xml_dir, showWarnings = FALSE)

status("Loading corpus (data/bes.rds)...")
bes <- readRDS("data/bes.rds")
stopifnot(all(rerun_ids %in% names(bes)))

fresh_papers <- list()
for (id in rerun_ids) {
  pdf_path <- file.path("D:/pdf", paste0(id, ".pdf"))
  stopifnot(file.exists(pdf_path))
  status("Converting %s to TEI XML via GROBID...", id)
  xml_path <- convert_grobid(pdf_path, save_path = xml_dir)
  status("Converting %s TEI XML to paper object...", id)
  p <- grobid_to_bibr(xml_path, save_path = NULL)
  stopifnot(metacheck:::.is_paper(p))
  fresh_papers[[id]] <- p
}
status("All %d papers re-imported successfully.", length(fresh_papers))

status("Substituting fresh paper objects into bes.rds for these %d IDs...", length(rerun_ids))
bes_backup_path <- "../backup_before_round2b_reimport_bes.rds"
if (!file.exists(bes_backup_path)) {
  saveRDS(bes, bes_backup_path)
  status("Backed up pre-reimport bes.rds to %s", bes_backup_path)
}
for (id in rerun_ids) {
  bes[[id]] <- fresh_papers[[id]]
}
saveRDS(bes, "data/bes.rds")
status("data/bes.rds updated with %d freshly re-imported papers.", length(rerun_ids))

target_papers <- bes[rerun_ids]

status("Running repo_check -> data_check -> code_check on the %d freshly re-imported papers...",
       length(rerun_ids))
res_repo_check_new <- module_run(target_papers, "repo_check", osf_license = TRUE, cache = TRUE)
res_data_check_new <- module_run(res_repo_check_new, "data_check", cache = TRUE, skip_on_api_limit = TRUE)
res_code_check_new <- module_run(res_data_check_new, "code_check", cache = TRUE, skip_on_api_limit = TRUE)

status("New results: repo_check %d rows, data_check %d rows, code_check %d rows (summary_table).",
       nrow(res_repo_check_new$summary_table), nrow(res_data_check_new$summary_table),
       nrow(res_code_check_new$summary_table))

dir.create("01_run_metacheck/rerun_round2b_reimport", showWarnings = FALSE)
save(res_repo_check_new, file = "01_run_metacheck/rerun_round2b_reimport/res_repo_check_new.RData")
save(res_data_check_new, file = "01_run_metacheck/rerun_round2b_reimport/res_data_check_new.RData")
save(res_code_check_new, file = "01_run_metacheck/rerun_round2b_reimport/res_code_check_new.RData")
status("Saved raw rerun output to 01_run_metacheck/rerun_round2b_reimport/.")

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

status("Dropping the %d target papers' OLD rows (from round 2's ineffective rerun) from the existing corpus-wide results...",
       length(rerun_ids))
res_repo_check_old_minus <- drop_ids(res_repo_check, rerun_ids)
res_data_check_old_minus <- drop_ids(res_data_check, rerun_ids)
res_code_check_old_minus <- drop_ids(res_code_check, rerun_ids)

status("Merging old-minus-10 with new-10 via the same combine_batches() logic the main pipeline uses...")
res_repo_check_merged <- combine_batches(list(res_repo_check_old_minus, res_repo_check_new))
res_data_check_merged <- combine_batches(list(res_data_check_old_minus, res_data_check_new))
res_code_check_merged <- combine_batches(list(res_code_check_old_minus, res_code_check_new))

stopifnot(nrow(res_repo_check_merged$summary_table) == nrow(res_repo_check$summary_table))
stopifnot(nrow(res_data_check_merged$summary_table) == nrow(res_data_check$summary_table))
stopifnot(nrow(res_code_check_merged$summary_table) == nrow(res_code_check$summary_table))
status("Row-count check passed: merged corpus-wide tables have the same total row count as before (%d/%d/%d).",
       nrow(res_repo_check_merged$summary_table), nrow(res_data_check_merged$summary_table),
       nrow(res_code_check_merged$summary_table))

dir.create("01_run_metacheck/backup_before_round2b_rerun", showWarnings = FALSE)
file.copy("01_run_metacheck/res_repo_check.RData",
          "01_run_metacheck/backup_before_round2b_rerun/res_repo_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_data_check.RData",
          "01_run_metacheck/backup_before_round2b_rerun/res_data_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_code_check.RData",
          "01_run_metacheck/backup_before_round2b_rerun/res_code_check.RData", overwrite = TRUE)
status("Backed up pre-rerun corpus-wide files to 01_run_metacheck/backup_before_round2b_rerun/.")

res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated with the 10 freshly re-imported papers.")
status("Next: rerun 01_comparison_data.R, 03_build_master_comparison.R, and 02a/02b/02c, then re-render the manuscript.")
