# Targeted re-import of the 7 papers manually audited as
# EXTRACTION_GAP_DOI_GARBLED whose specific whitespace-corruption pattern
# a code-level simulation suggested the current GROBID DOI-whitespace fix
# (commits e4b74e1, ac3b903) would now resolve. That simulation checked the
# fix's gsub rules against the row's recorded corrupted text, but did NOT
# confirm the fix had actually been re-applied to this paper's own cached
# text in bes.rds -- it had not (confirmed directly: 10.1111/1365-2435.14477's
# cached text still reads "doi. org/ 10.17026/ dans-zqs-g6cn", unfixed),
# because the fix only runs at PDF->GROBID->TEI->paper-object IMPORT time,
# never retroactively on already-cached text -- the same lesson already
# learned the hard way in 05_reimport_and_rerun_doi_whitespace_fix.R, which
# this script's structure directly reuses.
#
# Re-imports all 7 papers from their raw PDFs (D:/pdf/<article_id>.pdf)
# through convert_grobid() -> grobid_to_bibr(), substitutes the fresh paper
# objects into bes.rds for just these 7 IDs, then reruns
# repo_check -> data_check -> code_check and merges the results into the
# corpus-wide res_*_check.RData files.
#
# Usage (from inside code/): Rscript 01_run_metacheck/11_reimport_doi_garbled_papers.R

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

# The 7 article_ids audited as EXTRACTION_GAP_DOI_GARBLED, whose corruption
# pattern a code simulation suggested the current whitespace-collapse fix
# now resolves:
rerun_ids <- c(
  "10_1111_1365_2435_14477",
  "10_1111_1365_2435_14696",
  "10_1111_1365_2656_13893",
  "10_1111_1365_2745_13694",
  "10_1111_2041_210x_13821",
  "10_1111_2041_210x_13850",
  "10_1111_2041_210x_13681"
)
status("Re-importing %d papers from PDF via GROBID.", length(rerun_ids))

xml_dir <- "D:/grobid_reimport_doi_garbled"
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
bes_backup_path <- "../backup_before_doi_garbled_reimport_bes.rds"
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
res_repo_check_new <- module_run(target_papers, "repo_check", osf_license = TRUE, cache = FALSE)
res_data_check_new <- module_run(res_repo_check_new, "data_check", cache = FALSE, skip_on_api_limit = TRUE)
res_code_check_new <- module_run(res_data_check_new, "code_check", cache = FALSE, skip_on_api_limit = TRUE)

status("New results: repo_check %d rows, data_check %d rows, code_check %d rows (summary_table).",
       nrow(res_repo_check_new$summary_table), nrow(res_data_check_new$summary_table),
       nrow(res_code_check_new$summary_table))
print(res_repo_check_new$summary_table[, c("paper_id", "repo_n", "files_n")])

dir.create("01_run_metacheck/rerun_doi_garbled", showWarnings = FALSE)
save(res_repo_check_new, file = "01_run_metacheck/rerun_doi_garbled/res_repo_check_new.RData")
save(res_data_check_new, file = "01_run_metacheck/rerun_doi_garbled/res_data_check_new.RData")
save(res_code_check_new, file = "01_run_metacheck/rerun_doi_garbled/res_code_check_new.RData")
status("Saved raw rerun output to 01_run_metacheck/rerun_doi_garbled/.")

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

status("Dropping the %d target papers' OLD rows from the existing corpus-wide results...",
       length(rerun_ids))
res_repo_check_old_minus <- drop_ids(res_repo_check, rerun_ids)
res_data_check_old_minus <- drop_ids(res_data_check, rerun_ids)
res_code_check_old_minus <- drop_ids(res_code_check, rerun_ids)

status("Merging old-minus-7 with new-7 via the same combine_batches() logic the main pipeline uses...")
res_repo_check_merged <- combine_batches(list(res_repo_check_old_minus, res_repo_check_new))
res_data_check_merged <- combine_batches(list(res_data_check_old_minus, res_data_check_new))
res_code_check_merged <- combine_batches(list(res_code_check_old_minus, res_code_check_new))

stopifnot(nrow(res_repo_check_merged$summary_table) == nrow(res_repo_check$summary_table))
stopifnot(nrow(res_data_check_merged$summary_table) == nrow(res_data_check$summary_table))
stopifnot(nrow(res_code_check_merged$summary_table) == nrow(res_code_check$summary_table))
status("Row-count check passed: merged corpus-wide tables have the same total row count as before (%d/%d/%d).",
       nrow(res_repo_check_merged$summary_table), nrow(res_data_check_merged$summary_table),
       nrow(res_code_check_merged$summary_table))

# No full-copy backup step here (unlike the earliest rerun scripts): limited
# disk space. The original (unmodified) res_*_check.RData are not touched
# until the three save() calls below succeed.
status("Skipping backup copy step (limited disk space) -- writing directly.")

res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated with the 7 reran papers.")
status("Next: run targets::tar_make() from the project root to rebuild the comparison data, disagreement worklist, and manuscript.")
