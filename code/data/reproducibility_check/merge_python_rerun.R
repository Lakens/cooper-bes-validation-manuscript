#!/usr/bin/env Rscript

# Merge the Python rerun (rerun_python_papers.R: reproducibility_check() for
# the 71 papers with Python code, with a metacheck version that can run
# Python) into the corpus-wide reproducibility results. For those 71 papers
# every row is replaced: Python-only papers had no result before, and mixed
# Python/R papers had only their R scripts run.
#
# Reads each paper's saved result from code/data/batches/python_rerun_results/
# directly, so it needs neither Docker nor the cache drive.
#
# Usage (from the repository root):
#   Rscript code/data/reproducibility_check/merge_python_rerun.R
# then rebuild the A.7 detail file:
#   cd code && Rscript 01_run_metacheck/08_extract_reproducibility_detail.R

status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
  utils::flush.console()
}

data_dir <- "code/data"
ids <- read.csv(file.path(data_dir, "reproducibility_check_python_rerun_ids.csv"), stringsAsFactors = FALSE)$paper_id
files <- file.path(data_dir, "batches", "python_rerun_results", paste0(ids, ".rds"))
stopifnot(all(file.exists(files)))
status("%d Python papers, all with a saved result.", length(ids))

read_part <- function(f, part) {
  x <- readRDS(f)
  el <- if (part == "summary_table") x$summary_table else x$modules[["reproducibility_check"]][[part]]
  if (is.null(el) || !is.data.frame(el) || nrow(el) == 0) return(NULL)
  if (!"paper_id" %in% names(el)) el$paper_id <- x$paper_id
  el
}
new_summary <- dplyr::bind_rows(lapply(files, read_part, part = "summary_table"))
stopifnot(setequal(new_summary$paper_id, ids), !anyDuplicated(new_summary$paper_id))
# A paper whose rerun ended in an error has no repro_code_n (2026-10-12: 16
# papers, after the disk ran full and Docker stopped). Its earlier result is
# kept rather than replaced by nothing -- for papers that also have R code,
# that earlier result is a real check of their R scripts.
failed <- new_summary$paper_id[is.na(new_summary$repro_code_n)]
if (length(failed)) status("%d paper(s) without a rerun result keep their earlier result: %s",
                           length(failed), paste(failed, collapse = ", "))
ids <- setdiff(ids, failed)
files <- file.path(data_dir, "batches", "python_rerun_results", paste0(ids, ".rds"))
new_summary <- new_summary[new_summary$paper_id %in% ids, ]
new_table <- dplyr::bind_rows(lapply(files, read_part, part = "table"))

load(file.path(data_dir, "reproducibility_check_results.RData"))  # -> out
n_before <- nrow(out$results$summary_table)
out$results$table <- dplyr::bind_rows(out$results$table[!out$results$table$paper_id %in% ids, ], new_table)
out$results$summary_table <- dplyr::bind_rows(
  out$results$summary_table[!out$results$summary_table$paper_id %in% ids, ], new_summary)
out$results$summary_table <- out$results$summary_table[order(out$results$summary_table$paper_id), ]
stopifnot(nrow(out$results$summary_table) == n_before, !anyDuplicated(out$results$summary_table$paper_id))
attr(out, "python_rerun") <- list(paper_ids = ids, merged = format(Sys.time()))

save(out, file = file.path(data_dir, "reproducibility_check_results.RData"))
status("Merged: table %d rows, summary_table %d rows (%d papers replaced).",
       nrow(out$results$table), nrow(out$results$summary_table), length(ids))
