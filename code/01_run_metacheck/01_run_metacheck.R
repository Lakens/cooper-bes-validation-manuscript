# Run metacheck's core checks (repo_check -> data_check -> code_check)
# across the whole Cooper et al. BES validation corpus.
#
# PREREQUISITE: the papers themselves are downloaded and converted to a
# metacheck paperlist SEPARATELY, by build.R at the repository root (NOT
# this script) -- see README.md. This script only reads that
# already-built data/bes.rds; it never downloads a paper's own PDF/text.
#
# BATCHING: the corpus is processed in batches of BATCH_SIZE papers,
# each batch's result saved incrementally to 01_run_metacheck/batches/
# as soon as it finishes. This makes the whole run resumable: stopping
# the script (Ctrl+C, a crash, a machine reboot) and rerunning it later
# picks up at the first unfinished batch, rather than starting over --
# useful in practice, since a real run against Dryad-heavy batches can
# need to wait out an hourly/daily rate-limit reset.
#
# Usage (from inside code/): Rscript 01_run_metacheck/01_run_metacheck.R
library(metacheck)
library(dplyr)

# Downloaded repository files are cached in data/ (.metacheck_repo_cache,
# .metacheck_repo_info_cache, .metacheck_llm_cache), shared with
# data/reproducibility_check/run_reproducibility_check.R. Without this,
# metacheck defaults to the working directory (code/) and downloads
# everything again into a second cache.
options(metacheck.cache.dir = normalizePath("data", winslash = "/"))

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

# module_run() echoes its input `paper` object (the metacheck paperlist)
# back unchanged on its own $paper field, so a saved module-output
# RData file otherwise carries a full copy of the full extracted text
# of every paper it processed -- for this corpus, the copyrighted text
# of all 1861 BES papers, roughly 370MB per saved file. Nothing
# downstream of the FINAL, combined, corpus-wide files this script
# produces (the manuscript, the comparison scripts in
# 02_create_comparison_data/ and 03_comparing_results/) ever reads
# $paper back from them -- confirmed directly by grepping every script
# that loads one of these files for a `$paper` reference.
#
# strip_paper_text() is applied ONLY to the three final combined files
# saved at the end of this script, NOT to the per-batch files saved
# inside the loop below -- those still need $paper intact, because
# BATCH_RESUME's resume path (`load(path_repo)` then feeding the loaded
# res_repo_check back into `module_run("data_check", res_repo_check,
# ...)`) depends on module_run() reading `prev$paper` directly
# (R/module.R's `paper <- prev$paper`); stripping it from a per-batch
# file would silently break resuming an interrupted run from that
# batch.
strip_paper_text <- function(res) {
  res$paper <- NULL
  res
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
    # cache = TRUE: persists each repository's LISTING (dataset metadata +
    # file list, e.g. Dryad's 2-request dryad_info() call) to
    # .metacheck_repo_info_cache, so a repository already listed in an
    # earlier run or batch is never re-listed -- this is what
    # repo_info_cache() exists for (see metacheck#427's own background on
    # this exact quota-exhaustion pattern). Without it, every batch re-pays
    # every Dryad dataset's listing cost even when every one of its files
    # is already downloaded and cached.
    res_repo_check <- run_with_warnings("repo_check", batch_papers, "repo_check",
                                        osf_license = TRUE, cache = TRUE)
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

# Strip the full paper text ($paper) only now, from these final,
# combined, corpus-wide files -- NOT from the per-batch files saved
# above, which still need $paper intact for BATCH_RESUME to be able to
# feed a loaded res_repo_check/res_data_check back into module_run() as
# input (module_run() reads prev$paper directly, see R/module.R) if this
# script is interrupted and rerun later. These three corpus-wide files
# are the ones actually read downstream (by the manuscript and the
# comparison scripts), and nothing downstream ever needs $paper back.
res_repo_check <- strip_paper_text(res_repo_check)
res_data_check <- strip_paper_text(res_data_check)
res_code_check <- strip_paper_text(res_code_check)
save(res_repo_check, file = "01_run_metacheck/res_repo_check.RData")
save(res_data_check, file = "01_run_metacheck/res_data_check.RData")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Combined: repo_check %d rows, data_check %d rows, code_check %d rows (summary_table).",
       nrow(res_repo_check$summary_table), nrow(res_data_check$summary_table),
       nrow(res_code_check$summary_table))

status("Done. Run 01_run_metacheck/01_run_open_practices_oddpub.R next.")
