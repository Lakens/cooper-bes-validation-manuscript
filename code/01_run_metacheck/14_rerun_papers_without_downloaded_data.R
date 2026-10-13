# Follow-up to script 13. Its final pass (skip_on_api_limit = TRUE) accepted
# partial downloads instead of waiting out Dryad's download limit. For most
# papers that is harmless: the comparison only asks whether AT LEAST ONE
# usable data file was downloaded (mc_data_download in R/comparison_data.R),
# and 98 of the 114 papers with missing archive files already have one.
# These 16 papers have none yet, so their data_download result would reflect
# the interrupted download rather than metacheck (13 of them are coded "Yes"
# by Cooper et al.). They are rerun here with skip_on_api_limit = FALSE, i.e.
# every host rate limit is waited out, and no Dryad deferral.
#
# The watchdog, worker, and merge helpers are taken from script 13 unchanged
# (parsed from that file by name), so both scripts behave the same.
#
# Usage (from inside code/): Rscript 01_run_metacheck/14_rerun_papers_without_downloaded_data.R
#   or, for other papers: ... 14_rerun_papers_without_downloaded_data.R <output_folder> <paper_id> ...

library(metacheck)
library(dplyr)

cache_root <- Sys.getenv("METACHECK_CACHE_ROOT", "D:/")
options(metacheck.cache.dir = cache_root)
if (cache_root == "D:/") stopifnot(dir.exists("D:/.metacheck_repo_cache"))

# Helper functions from script 13, by name.
helpers <- c("status", "strip_paper_text", "combine_batches", "drop_ids", "run_one_paper",
             "dryad_wait_minutes", "io_of", "start_paper", "check_paper")
for (e in parse("01_run_metacheck/13_rerun_failed_archive_downloads.R")) {
  if (is.call(e) && identical(e[[1]], as.name("<-")) && as.character(e[[2]])[1] %in% helpers) eval(e)
}
stopifnot(all(vapply(helpers, exists, logical(1))))
# The merge helpers come from the shared, tested R/corpus_merge.R instead
# (overriding script 13's copies): its combine_batches() no longer nests
# non-table fields one level deeper per merge, and merge_rerun() checks the
# result still has one summary row per paper.
source("../R/corpus_merge.R")
source("../R/corpus_files.R")   # read/save the results in parts (2 GB limit)

status("Cache root: %s", cache_root)
status("metacheck version: %s (RemoteSha %s)", as.character(packageVersion("metacheck")),
       utils::packageDescription("metacheck")[["RemoteSha"]] %||% "unknown")

rerun_ids <- c("10_1002_2688_8319_12405", "10_1002_pan3_10461", "10_1111_1365_2435_12871",
               "10_1111_1365_2435_13191", "10_1111_1365_2435_13357", "10_1111_1365_2656_13195",
               "10_1111_1365_2664_13041", "10_1111_1365_2664_13043", "10_1111_1365_2664_13525",
               "10_1111_1365_2664_13539", "10_1111_1365_2664_14129", "10_1111_1365_2745_13771",
               "10_1111_2041_210x_13324", "10_1111_2041_210x_13817", "10_1111_2041_210x_14029",
               "10_1111_2041_210x_14468")

out_dir <- "01_run_metacheck/rerun_papers_without_downloaded_data"

# Optional arguments: an output folder name, then paper ids. Used on
# 2026-10-12 for four papers whose files were lost to problems during the
# script 13 rerun itself, not to anything in the papers: 12820 (Dryad zips
# not read in the final pass), 13447 (Zenodo briefly answered "record not
# found"), 14821 (4TU.ResearchData answered 503), 13709 (two cache files on
# D: could not be read).
args <- commandArgs(TRUE)
if (length(args) >= 2) {
  out_dir <- file.path("01_run_metacheck", args[1])
  rerun_ids <- args[-1]
}
manifest_dir <- file.path(out_dir, "manifests")
paper_dir <- file.path(out_dir, "papers")
plog_dir <- file.path(out_dir, "paper_logs")
for (d in c(manifest_dir, paper_dir, plog_dir)) dir.create(d, showWarnings = FALSE, recursive = TRUE)
writeLines(rerun_ids, file.path(out_dir, "rerun_ids.txt"))

HANG_MINUTES <- 15
DRYAD_DEFER_MINUTES <- Inf   # never defer: wait out every Dryad limit
N_WORKERS <- 2
big_budget <- c()            # all 16 use the 2 GB budget of start_paper()

bes <- readRDS("data/bes.rds")
stopifnot(all(rerun_ids %in% names(bes)))
load("01_run_metacheck/res_repo_check.RData")
paper_repos <- split(res_repo_check$table$repo_url, res_repo_check$table$paper_id)
rm(res_repo_check); invisible(gc())

# One pass, final_pass = FALSE so skip_on_api_limit = FALSE throughout.
todo <- rerun_ids[!file.exists(file.path(paper_dir, paste0(rerun_ids, ".rds")))]
status("%d paper(s) to run, %d at a time, waiting out every rate limit.", length(todo), N_WORKERS)
queue <- todo; running <- list(); n_finished <- 0
while (length(queue) > 0 || length(running) > 0) {
  while (length(running) < N_WORKERS && length(queue) > 0) {
    busy <- unlist(lapply(running, function(s) s$repos))
    pick <- which(vapply(queue, function(id) !any(unique(paper_repos[[id]]) %in% busy), logical(1)))
    if (length(pick) == 0) break
    id <- queue[pick[1]]; queue <- queue[-pick[1]]
    running[[id]] <- start_paper(id, FALSE)
  }
  Sys.sleep(15)
  for (id in names(running)) {
    res <- check_paper(running[[id]])
    if (res == "running") next
    n_finished <- n_finished + 1
    n_done <- length(list.files(paper_dir, "[.]rds$"))
    status("Paper %d/%d %s: %s (%.0f min). Done %d of %d, left %d.", n_finished, length(todo), id, res,
           as.numeric(difftime(Sys.time(), running[[id]]$t0, units = "mins")), n_done,
           length(rerun_ids), length(rerun_ids) - n_done)
    running[[id]] <- NULL
  }
}

# ── Merge, one corpus file at a time ────────────────────────────────────────
# One file at a time, written to a temporary file that is loaded back
# before it replaces the original: script 13 held all three in memory and
# its last save failed part-way (2026-10-12), leaving a damaged file.
rerun_ok <- sub("[.]rds$", "", list.files(paper_dir, "[.]rds$"))
writeLines(setdiff(rerun_ids, rerun_ok), file.path(out_dir, "not_rerun_ids.txt"))
status("%d of %d papers rerun; kept original results: %s", length(rerun_ok), length(rerun_ids),
       paste(setdiff(rerun_ids, rerun_ok), collapse = ", "))
done <- lapply(file.path(paper_dir, paste0(rerun_ok, ".rds")), readRDS)

for (part in c("repo", "data", "code")) {
  obj <- paste0("res_", part, "_check")
  file <- sprintf("01_run_metacheck/%s.RData", obj)
  new <- combine_batches(lapply(done, `[[`, part))
  old <- read_corpus_result(file, obj)
  merged <- strip_paper_text(merge_rerun(old, new))
  stopifnot(nrow(merged$summary_table) == nrow(old$summary_table))
  rm(old, new); invisible(gc())
  save_corpus_result(merged, obj, file)
  rm(merged); invisible(gc())
  e <- new.env(); load(file, envir = e)
  stopifnot(nrow(e[[obj]]$summary_table) == 1861)
  rm(e); invisible(gc())
  status("%s merged, saved in parts, and reloaded (1861 papers).", obj)
}
status("Done. Corpus-wide res_*_check.RData files updated with the %d reran papers.", length(rerun_ok))
