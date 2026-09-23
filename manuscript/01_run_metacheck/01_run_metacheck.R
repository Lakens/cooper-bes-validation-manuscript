# Run metacheck's core checks (repo_check -> data_check -> code_check)
# across the whole Cooper et al. BES validation corpus.
#
# PREREQUISITE: the papers themselves are downloaded and converted to a
# metacheck paperlist SEPARATELY, by build.R at the repository root (NOT
# this script) -- see final_pipeline/README.md. This script only reads
# that already-built data/bes.rds; it never downloads a paper's own
# PDF/text.
#
# BATCHING: the corpus is processed in batches of BATCH_SIZE papers,
# each batch's result saved incrementally to data/batches/ as soon as it
# finishes. This makes the whole run resumable: stopping the script
# (Ctrl+C, a crash, a machine reboot) and rerunning it later picks up at
# the first unfinished batch, rather than starting over -- useful in
# practice, since a real run against Dryad-heavy batches can need to
# wait out an hourly/daily rate-limit reset.
#
# Usage (from inside manuscript/): Rscript 01_run_metacheck/01_run_metacheck.R
#
# Copy of final_pipeline/01_run_metacheck.R, relocated into its own
# 01_run_metacheck/ folder together with its outputs so this stage of the
# pipeline is self-contained; only the output paths below were changed
# (BATCH_DIR, WARNING_LOG, and the three save() calls at the end), all
# now relative to this folder instead of data/. The helper functions
# below were folded in from final_pipeline/helpers.R for the same reason
# -- 02_run_open_practices_oddpub.R also needs run_with_warnings() and
# combine_batches(), and keeps its own small copy of them (see that
# script's own comment).
library(metacheck)
library(dplyr)

# Progress line, timestamped, flushed immediately so `tail -f` (or the
# equivalent) on stdout shows live status during a run that takes hours
# across ~1861 papers.
status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              sprintf(...)))
  utils::flush.console()
}

# R's default non-interactive behaviour defers warnings and, once more
# than 50 accumulate in one script run, prints only a COUNT at the very
# end with no way to retrieve the actual text afterward. run_with_warnings()
# wraps a single module_run() call and appends every warning it raises,
# as it happens, to WARNING_LOG (must be set by the caller before use)
# with a timestamp and the module name, so a long run's warnings survive.
run_with_warnings <- function(module_name, ...) {
  withCallingHandlers(
    module_run(...),
    warning = function(w) {
      cat(sprintf("[%s] %s: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                  module_name, conditionMessage(w)),
          file = WARNING_LOG, append = TRUE)
      invokeRestart("muffleWarning")
    }
  )
}

# Combine a list of per-batch metacheck_module_output objects into one
# corpus-wide object with the same shape module_run() itself produces.
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
      # Drop 0-row frames before bind_rows(): an empty batch's field can
      # have a mismatched column type vs. a populated batch's, which
      # bind_rows() errors on.
      nonempty <- vals[vapply(vals, nrow, integer(1)) > 0]
      out[[f]] <- if (length(nonempty) > 0) dplyr::bind_rows(nonempty) else vals[[1]]
    } else {
      out[[paste0(f, "_by_batch")]] <- vals
    }
  }
  out
}

BATCH_SIZE   <- 50
BATCH_RESUME <- TRUE
BATCH_DIR    <- "01_run_metacheck/batches"
dir.create(BATCH_DIR, showWarnings = FALSE, recursive = TRUE)

WARNING_LOG <- "01_run_metacheck/warnings.log"

status("Loading corpus (built separately by ../build.R)...")
bes <- readRDS("data/bes.rds")
n_papers     <- length(bes)
batch_starts <- seq(1, n_papers, by = BATCH_SIZE)
n_batches    <- length(batch_starts)
status("Processing %d papers in %d batch(es) of up to %d papers each.",
       n_papers, n_batches, BATCH_SIZE)

repo_check_batches <- vector("list", n_batches)
data_check_batches <- vector("list", n_batches)
code_check_batches <- vector("list", n_batches)

for (b in seq_len(n_batches)) {
  batch_id  <- sprintf("%03d", b)
  start_idx <- batch_starts[b]
  end_idx   <- min(start_idx + BATCH_SIZE - 1, n_papers)
  batch_ids <- names(bes)[start_idx:end_idx]

  path_repo <- file.path(BATCH_DIR, sprintf("res_repo_check_batch%s.RData", batch_id))
  path_data <- file.path(BATCH_DIR, sprintf("res_data_check_batch%s.RData", batch_id))
  path_code <- file.path(BATCH_DIR, sprintf("res_code_check_batch%s.RData", batch_id))

  if (BATCH_RESUME && file.exists(path_repo) && file.exists(path_data) &&
      file.exists(path_code)) {
    status("Batch %d/%d (papers %d-%d): already done, loading from disk.",
           b, n_batches, start_idx, end_idx)
    load(path_repo); load(path_data); load(path_code)
  } else if (BATCH_RESUME && file.exists(path_repo) &&
             !(file.exists(path_data) && file.exists(path_code))) {
    # repo_check's own result (the list of what's out there) does not
    # change on a retry -- only rerun the download-dependent stages.
    load(path_repo)
    status("Batch %d/%d (papers %d-%d): retrying data_check -> code_check (cached files reused, only missing ones re-attempt)...",
           b, n_batches, start_idx, end_idx)
    res_data_check <- run_with_warnings("data_check", res_repo_check, "data_check",
                                        cache = TRUE, skip_on_api_limit = TRUE)
    save(res_data_check, file = path_data)
    res_code_check <- run_with_warnings("code_check", res_data_check, "code_check",
                                        cache = TRUE, skip_on_api_limit = TRUE)
    save(res_code_check, file = path_code)
    status("Batch %d/%d retry done.", b, n_batches)
  } else {
    status("Batch %d/%d (papers %d-%d): running repo_check -> data_check -> code_check...",
           b, n_batches, start_idx, end_idx)
    batch_papers <- bes[batch_ids]

    # osf_license = TRUE: pays one extra API request per OSF project
    # (repo_check's default, FALSE, skips this) so OSF's own licence
    # field reaches repo_metadata alongside every other platform's.
    res_repo_check <- run_with_warnings("repo_check", batch_papers, "repo_check",
                                        osf_license = TRUE)
    save(res_repo_check, file = path_repo)

    # skip_on_api_limit = TRUE: a confirmed rate-limit-exhausted file
    # (e.g. Dryad's per-day quota) skips instead of blocking the whole
    # run for up to its reset window.
    res_data_check <- run_with_warnings("data_check", res_repo_check, "data_check",
                                        cache = TRUE, skip_on_api_limit = TRUE)
    save(res_data_check, file = path_data)

    res_code_check <- run_with_warnings("code_check", res_data_check, "code_check",
                                        cache = TRUE, skip_on_api_limit = TRUE)
    save(res_code_check, file = path_code)

    status("Batch %d/%d done.", b, n_batches)
  }

  repo_check_batches[[b]] <- res_repo_check
  data_check_batches[[b]] <- res_data_check
  code_check_batches[[b]] <- res_code_check
}

status("Combining %d batch(es) into corpus-wide results...", n_batches)
res_repo_check <- combine_batches(repo_check_batches)
res_data_check <- combine_batches(data_check_batches)
res_code_check <- combine_batches(code_check_batches)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Combined: repo_check %d rows, data_check %d rows, code_check %d rows (summary_table).",
       nrow(res_repo_check$summary_table), nrow(res_data_check$summary_table),
       nrow(res_code_check$summary_table))

status("Done. Run 01_run_metacheck/01_run_open_practices_oddpub.R next.")
