# Run metacheck's open_practices module and ODDPub across the whole
# Cooper et al. BES validation corpus.
#
# PREREQUISITE: run 01_run_metacheck.R first (or at least have its
# outputs on disk) -- not because this script consumes their result
# (open_practices does not call get_prev_outputs() on any other module,
# and ODDPub is called directly on the paperlist, not via module_run()),
# but because both scripts batch over the same data/bes.rds corpus and
# are meant to be run as one pipeline, in order.
#
# This is a copy of the open_practices/ODDPub section originally at the
# end of code_data_preparation/01_run_checks.R (that script's own
# repo_check/data_check/code_check section is superseded here by
# 01_run_metacheck.R instead -- see this folder's own provenance notes).
# Split into its own file, with only the output paths changed (BATCH_DIR,
# and the two save() calls at the end), all now relative to this folder.
#
# BATCHING: per-batch saving here, exactly like 01_run_metacheck.R, and
# for the same reason -- a pass over the whole corpus in one go at the
# end means a run killed partway through has to redo EVERY batch's
# open_practices/ODDPub from scratch. Per-batch saving avoids that.
# ODDPub is markedly slower than open_practices (it does its own
# sentence-level text mining per paper); confirmed to take ~55 minutes
# on a 250-paper subset in the original run.
#
# Usage (from inside manuscript/): Rscript 01_run_metacheck/02_run_open_practices_oddpub.R
library(metacheck)
library(dplyr)

source("01_run_metacheck/oddpub_open_practices.R")

# status()/run_with_warnings()/combine_batches() duplicated here from
# 01_run_metacheck.R (this folder's former shared helpers.R was folded
# into that script instead of kept separate -- see its own comment).
status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              sprintf(...)))
  utils::flush.console()
}

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

BATCH_SIZE   <- 50
BATCH_RESUME <- TRUE
BATCH_DIR    <- "01_run_metacheck/batches"
dir.create(BATCH_DIR, showWarnings = FALSE, recursive = TRUE)

WARNING_LOG <- "01_run_metacheck/warnings_open_practices.log"

status("Loading corpus (built separately by ../build.R)...")
bes <- readRDS("data/bes.rds")
n_papers     <- length(bes)
batch_starts <- seq(1, n_papers, by = BATCH_SIZE)
n_batches    <- length(batch_starts)
status("Processing %d papers in %d batch(es) of up to %d papers each.",
       n_papers, n_batches, BATCH_SIZE)

open_practices_batches <- vector("list", n_batches)
oddpub_batches <- vector("list", n_batches)
for (b in seq_len(n_batches)) {
  batch_id  <- sprintf("%03d", b)
  start_idx <- batch_starts[b]
  end_idx   <- min(start_idx + BATCH_SIZE - 1, n_papers)
  batch_ids <- names(bes)[start_idx:end_idx]

  path_op <- file.path(BATCH_DIR, sprintf("res_open_practices_batch%s.RData", batch_id))
  path_od <- file.path(BATCH_DIR, sprintf("res_oddpub_batch%s.RData", batch_id))

  if (BATCH_RESUME && file.exists(path_op) && file.exists(path_od)) {
    status("open_practices/ODDPub batch %d/%d: already done, loading from disk.",
           b, n_batches)
    load(path_op); load(path_od)
  } else {
    status("open_practices/ODDPub batch %d/%d (papers %d-%d)...",
           b, n_batches, start_idx, end_idx)
    batch_papers <- bes[batch_ids]

    res_open_practices <- run_with_warnings("open_practices", batch_papers, "open_practices")
    save(res_open_practices, file = path_op)

    res_oddpub <- oddpub_open_practices(batch_papers)
    save(res_oddpub, file = path_od)
  }

  open_practices_batches[[b]] <- res_open_practices
  oddpub_batches[[b]] <- res_oddpub
}

res_open_practices <- combine_batches(open_practices_batches)
res_oddpub <- combine_batches(oddpub_batches)
save(res_open_practices, file = "01_run_metacheck/res_open_practices.RData")
save(res_oddpub, file = "01_run_metacheck/res_oddpub.RData")
status("open_practices done (%d rows in summary_table); ODDPub done (%d rows in summary_table).",
       nrow(res_open_practices$summary_table), nrow(res_oddpub$summary_table))

status("All checks complete.")
