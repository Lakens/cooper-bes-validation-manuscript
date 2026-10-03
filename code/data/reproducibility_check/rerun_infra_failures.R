#!/usr/bin/env Rscript

# Rerun exactly the 16 papers whose reproducibility_check() result in the
# full-corpus run was a synthetic "error" stand-in caused by an
# INFRASTRUCTURE failure (callr subprocess crash, or a transient Docker
# Desktop outage) rather than a genuine reproducibility problem with the
# paper's own code. Extracted by grepping the full run's log
# (reproducibility_check/run_full_1batch_20260920_214416.log) for the
# `[repro]   x  '<paper_id>' failed: ...` lines .reproducibility_check_batch()
# prints when a worker's own get_result() call errors.
#
# This is a standalone script (not run_reproducibility_check.R with some
# subsetting flag) because these 16 papers are scattered arbitrarily through
# the 1861-paper corpus, not a contiguous first-N range that --max-papers
# could express.
#
# Output is a SEPARATE .RData file (reproducibility_check_infra_rerun.RData),
# never overwriting the main corpus's reproducibility_check_results_execute.RData
# -- merging these 16 corrected results back into the main combined output is
# a deliberate follow-up step, not done automatically here.

suppressPackageStartupMessages(library(metacheck))
suppressPackageStartupMessages(library(dplyr))

TARGET_PAPER_IDS <- c(
  "10_1002_2688_8319_12123", "10_1002_2688_8319_12128", "10_1111_1365_2656_13193",
  "10_1111_1365_2664_13190", "10_1111_1365_2664_13546", "10_1111_1365_2664_13630",
  "10_1111_1365_2664_13728", "10_1111_1365_2664_13913", "10_1111_2041_210x_13384",
  "10_1111_2041_210x_13440", "10_1111_2041_210x_14002", "10_1111_2041_210x_14125",
  "10_1111_2041_210x_14126", "10_1111_2041_210x_14277", "10_1111_2041_210x_14366",
  "10_1111_2041_210x_14430"
)

infer_repo_root <- function() {
  args_vec <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args_vec, value = TRUE)
  if (length(file_arg) > 0L) {
    script_path <- sub("^--file=", "", file_arg[1L])
    if (nzchar(script_path)) {
      script_dir <- normalizePath(dirname(script_path), winslash = "/", mustWork = FALSE)
      return(dirname(script_dir))
    }
  }
  dirname(getwd())
}

locate_bes <- function(repo_root) {
  candidates <- c(
    file.path(repo_root, "bes.rds"),
    file.path(repo_root, "manuscript", "data", "bes.rds")
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0L) stop("Could not find bes.rds. Expected one of: ", paste(candidates, collapse = ", "))
  hit[1L]
}

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

# -- Always install fresh from dev, same as run_reproducibility_check.R -----
if ("package:metacheck" %in% search()) detach("package:metacheck", unload = TRUE, character.only = TRUE)
message("Installing scienceverse/metacheck@dev from GitHub...")
remotes::install_github("scienceverse/metacheck", ref = "dev", upgrade = "never", force = TRUE)
suppressPackageStartupMessages(library(metacheck))
cat("metacheck version: ", as.character(packageVersion("metacheck")), "\n", sep = "")

repo_root <- infer_repo_root()
options(metacheck.cache.dir = repo_root)
cat("metacheck cache dir: ", repo_root, "\n", sep = "")

bes_path <- locate_bes(repo_root)
cat("Loading corpus from: ", bes_path, "\n", sep = "")
bes <- readRDS(bes_path)

ids <- vapply(seq_along(bes), function(i) tryCatch(paper_id(bes[i]), error = function(e) NA_character_), character(1))
idx <- match(TARGET_PAPER_IDS, ids)
if (any(is.na(idx))) stop("Could not find in corpus: ", paste(TARGET_PAPER_IDS[is.na(idx)], collapse = ", "))
status("Found all %d target papers in the corpus.", length(TARGET_PAPER_IDS))

target_papers <- bes[idx]

data_dir <- file.path(repo_root, "data")
results_dir <- file.path(data_dir, "batches", "infra_rerun_results")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
warning_log <- file.path(data_dir, "reproducibility_check_infra_rerun_warnings.log")

# workers = 4 (not 5): a small, fixed batch of 16 papers doesn't need the
# full corpus run's worker count, and this leaves headroom in case anything
# else is using the machine.
status("Running reproducibility_check on %d paper(s), up to 4 at a time...", length(target_papers))
res <- withCallingHandlers(
  module_run(target_papers, "reproducibility_check",
             execute = TRUE, sandbox = "docker", install_missing = TRUE,
             timeout = 3000L, cache = TRUE, skip_on_api_limit = TRUE,
             workers = 4L, results_dir = results_dir),
  warning = function(w) {
    cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), conditionMessage(w)),
        file = warning_log, append = TRUE)
    invokeRestart("muffleWarning")
  }
)

out_path <- file.path(data_dir, "reproducibility_check_infra_rerun.RData")
save(res, file = out_path)
cat("Saved rerun output to: ", out_path, "\n", sep = "")
cat("table rows: ", nrow(res$table), "\n", sep = "")
cat("summary_table rows: ", nrow(res$summary_table), "\n", sep = "")
cat("Finished.\n")
