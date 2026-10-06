# Targeted rerun of the 13 papers confirmed, in scienceverse/metacheck#461,
# to cite a repository on a host or DOI prefix that was missing from the
# registry and has now been added in scienceverse/metacheck#464 (merged to
# dev, installed here 2026-10-06): VTechData, USDA Ag Data Commons,
# U. Adelaide (Figshare vanity hosts), UCL's missing 10.5522 DOI prefix,
# U. Stirling DataSTORRE (DSpace legacy), and Cornell eCommons + Apollo
# Cambridge (DSpace 7+, Cambridge via the new UI-host/API-host alias). NOT
# a full corpus rerun -- only these 13 papers' metacheck output has any
# chance of changing, since every other host/prefix in the registry is
# unchanged on dev relative to what originally produced
# res_*_check.RData. EDI (DataONE, issue #461's other open case) is
# deliberately excluded: #464's own PR description says it was NOT added,
# since it needs real URL-construction code, not a table entry.
#
# Reuses the exact same module_run() call conventions (cache = FALSE here,
# since every one of these hosts was previously unsupported and could only
# have a stale/absent cache entry from before #464) and the same
# combine_batches()/drop_ids() helpers as 01_run_metacheck.R and the prior
# 03/04/06/07_*.R targeted reruns, so the result is byte-for-byte
# equivalent in shape to a full corpus rerun, only narrower in scope.
#
# Usage (from inside code/): Rscript 01_run_metacheck/08_rerun_issue_461_registry_papers.R

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

# The 13 article_ids from issue #461 confirmed, live, to resolve once their
# host/prefix was added in #464 (DOI -> host mapping per the issue's own
# write-up and the maintainer's follow-up comment on what was actually
# merged):
#   10_1002_2688_8319_12070  UCL            rdr.ucl.ac.uk (10.5522 prefix)
#   10_1002_pan3_10491       UCL            rdr.ucl.ac.uk (10.5522 prefix)
#   10_1002_pan3_10689       VTechData      data.lib.vt.edu
#   10_1111_1365_2656_13439  VTechData      data.lib.vt.edu
#   10_1111_1365_2664_13065  USDA Ag Data Commons  agdatacommons.nal.usda.gov
#   10_1111_1365_2664_13397  U. Adelaide    adelaide.figshare.com
#   10_1111_1365_2664_13035  U. Stirling    datastorre.stir.ac.uk (DSpace legacy)
#   10_1111_1365_2664_14198  U. Stirling    datastorre.stir.ac.uk (DSpace legacy)
#   10_1111_1365_2664_14415  Cornell        ecommons.cornell.edu (DSpace 7+)
#   10_1002_pan3_10406       Cambridge      www.repository.cam.ac.uk (Apollo, DSpace 7+)
#   10_1002_pan3_14          Cambridge      www.repository.cam.ac.uk (Apollo, DSpace 7+)
#   10_1111_1365_2656_13970  Cambridge      www.repository.cam.ac.uk (Apollo, DSpace 7+)
#   10_1111_1365_2664_13614  Cambridge      www.repository.cam.ac.uk (Apollo, DSpace 7+)
rerun_ids <- c(
  "10_1002_2688_8319_12070",
  "10_1002_pan3_10491",
  "10_1002_pan3_10689",
  "10_1111_1365_2656_13439",
  "10_1111_1365_2664_13065",
  "10_1111_1365_2664_13397",
  "10_1111_1365_2664_13035",
  "10_1111_1365_2664_14198",
  "10_1111_1365_2664_14415",
  "10_1002_pan3_10406",
  "10_1002_pan3_14",
  "10_1111_1365_2656_13970",
  "10_1111_1365_2664_13614"
)
status("Rerunning %d papers from issue #461 (cache = FALSE): %s",
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
print(res_repo_check_new$summary_table)

# Save the raw new-only results first, before touching the corpus-wide
# files, so a crash/interruption during the merge step below never loses
# this rerun's output.
dir.create("01_run_metacheck/rerun_issue_461", showWarnings = FALSE)
save(res_repo_check_new, file = "01_run_metacheck/rerun_issue_461/res_repo_check_new.RData")
save(res_data_check_new, file = "01_run_metacheck/rerun_issue_461/res_data_check_new.RData")
save(res_code_check_new, file = "01_run_metacheck/rerun_issue_461/res_code_check_new.RData")
status("Saved raw rerun output to 01_run_metacheck/rerun_issue_461/.")

status("Loading existing corpus-wide results to merge into...")
load("01_run_metacheck/res_repo_check.RData")  # res_repo_check
load("01_run_metacheck/res_data_check.RData")  # res_data_check
load("01_run_metacheck/res_code_check.RData")  # res_code_check

status("Dropping the %d target papers' OLD rows from the existing corpus-wide results...",
       length(rerun_ids))
res_repo_check_old_minus <- drop_ids(res_repo_check, rerun_ids)
res_data_check_old_minus <- drop_ids(res_data_check, rerun_ids)
res_code_check_old_minus <- drop_ids(res_code_check, rerun_ids)

status("Merging old-minus-13 with new-13 via the same combine_batches() logic the main pipeline uses...")
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
# prior targeted-rerun scripts.
dir.create("01_run_metacheck/backup_before_issue_461_rerun", showWarnings = FALSE)
file.copy("01_run_metacheck/res_repo_check.RData",
          "01_run_metacheck/backup_before_issue_461_rerun/res_repo_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_data_check.RData",
          "01_run_metacheck/backup_before_issue_461_rerun/res_data_check.RData", overwrite = TRUE)
file.copy("01_run_metacheck/res_code_check.RData",
          "01_run_metacheck/backup_before_issue_461_rerun/res_code_check.RData", overwrite = TRUE)
status("Backed up pre-rerun corpus-wide files to 01_run_metacheck/backup_before_issue_461_rerun/.")

res_repo_check <- strip_paper_text(res_repo_check_merged)
res_data_check <- strip_paper_text(res_data_check_merged)
res_code_check <- strip_paper_text(res_code_check_merged)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Done. Corpus-wide res_*_check.RData files updated with the 13 reran papers.")
status("Next: run targets::tar_make() from the project root to rebuild the comparison data, disagreement worklist, and manuscript.")
