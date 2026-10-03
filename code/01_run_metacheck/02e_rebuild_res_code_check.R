# One-off repair: res_code_check.RData was left corrupted after a
# save() was interrupted mid-write while 02d_strip_paper_text_existing.R
# was being stopped for an unrelated reason. Rebuilds it from the 38
# intact per-batch res_code_check_batch*.RData files (the same
# combine_batches() logic 01_run_metacheck.R itself uses) and strips
# $paper from the result before saving, in one pass.
#
# Usage (from inside code/): Rscript 01_run_metacheck/02e_rebuild_res_code_check.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
library(dplyr)
library(metacheck)  # for paperlist(), used by combine_batches() below

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

batch_dir <- "01_run_metacheck/batches"
batch_files <- sort(list.files(batch_dir, pattern = "^res_code_check_batch\\d+\\.RData$", full.names = TRUE))
status("Found %d res_code_check batch files.", length(batch_files))
stopifnot(length(batch_files) == 38)

status("Loading all 38 batches...")
batches <- vector("list", length(batch_files))
for (i in seq_along(batch_files)) {
  e <- new.env()
  load(batch_files[i], envir = e)
  batches[[i]] <- e$res_code_check
}
status("Loaded. Combining...")

res_code_check <- combine_batches(batches)
rm(batches)
gc()

status("Combined. nrow(table) = %d, nrow(summary_table) = %d",
       nrow(res_code_check$table), nrow(res_code_check$summary_table))

res_code_check$paper <- NULL
status("Stripped $paper. Saving...")
save(res_code_check, file = "01_run_metacheck/res_code_check.RData")
status("Saved (%.1f MB).", file.size("01_run_metacheck/res_code_check.RData") / 1e6)
status("Done.")
