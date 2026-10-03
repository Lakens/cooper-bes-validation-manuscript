# One-off remediation script: strips the $paper field (the full
# extracted text of every paper, ~370MB per combined file) from
# already-saved module-output RData files -- both the three final
# combined files and every per-batch checkpoint file. These were saved
# before 01_run_metacheck.R itself was fixed to stop writing $paper
# into the files it produces.
#
# NOTE ON BATCH FILES SPECIFICALLY: stripping $paper from a per-batch
# file removes that specific batch's ability to support
# 01_run_metacheck.R's BATCH_RESUME feature (which needs $paper intact
# to feed a loaded res_repo_check back into module_run() for the next
# stage) -- this is an intentional, accepted tradeoff for an already-
# finished run whose batches are being kept only as a historical
# record, not for resuming computation. Do not run this against batch
# files from a run that might still need to resume.
#
# Takes an optional single argument: "combined" (just the 3 big final
# files) or "batches" (all per-batch files). Run each in its own fresh
# Rscript process -- a single process loading one ~1.9GB combined file
# after another can accumulate memory beyond what load()/save() alone
# would suggest, the same lesson learned rendering the manuscript
# itself.
#
# Usage (from inside code/):
#   Rscript 01_run_metacheck/02d_strip_paper_text_existing.R combined
#   Rscript 01_run_metacheck/02d_strip_paper_text_existing.R batches

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))

strip_one_file <- function(path, object_name) {
  if (!file.exists(path)) {
    status("  skip (not found): %s", path)
    return(invisible(NULL))
  }
  size_before <- file.size(path)
  e <- new.env()
  load(path, envir = e)
  obj <- e[[object_name]]
  if (is.null(obj)) {
    status("  skip (object '%s' not found in file): %s", object_name, path)
    return(invisible(NULL))
  }
  if (is.null(obj$paper)) {
    status("  already stripped: %s", path)
    return(invisible(NULL))
  }
  obj$paper <- NULL
  e[[object_name]] <- obj
  save(list = object_name, envir = e, file = path)
  size_after <- file.size(path)
  status("  stripped: %s (%.1f MB -> %.1f MB)", path, size_before / 1e6, size_after / 1e6)
  rm(obj); rm(e)
  gc()
}

mode <- if (length(commandArgs(trailingOnly = TRUE)) > 0) commandArgs(trailingOnly = TRUE)[1] else "combined"

if (mode == "combined") {
  status("Stripping the three final combined files (one at a time)...")
  strip_one_file("01_run_metacheck/res_repo_check.RData", "res_repo_check")
  strip_one_file("01_run_metacheck/res_data_check.RData", "res_data_check")
  strip_one_file("01_run_metacheck/res_code_check.RData", "res_code_check")
} else if (mode == "batches") {
  status("Stripping every per-batch checkpoint file in 01_run_metacheck/batches/...")
  batch_dir <- "01_run_metacheck/batches"
  batch_files <- list.files(batch_dir, pattern = "^res_(repo|data|code)_check_batch\\d+\\.RData$", full.names = TRUE)
  status("Found %d batch files.", length(batch_files))
  for (f in batch_files) {
    object_name <- sub("_batch\\d+\\.RData$", "", basename(f))
    strip_one_file(f, object_name)
  }
} else {
  stop("Unknown mode: ", mode, " (expected 'combined' or 'batches')")
}

status("Done.")
