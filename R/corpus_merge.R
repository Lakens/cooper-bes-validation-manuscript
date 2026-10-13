# Combining and merging metacheck module results across batches and
# reruns. Used by the corpus run (code/01_run_metacheck/01_run_metacheck.R)
# and the rerun-and-merge scripts, and tested in tests/testthat/.

# module_run() echoes its input paperlist on $paper, so a saved result
# would otherwise carry the full (copyrighted) text of every paper; nothing
# downstream reads it.
strip_paper_text <- function(res) {
  res$paper <- NULL
  res
}

# Combine a list of metacheck_module_output objects into one with the same
# shape module_run() itself produces. Tables are stacked; fields that are
# not tables are kept per batch in a list named "<field>_by_batch". A field
# that is ALREADY a per-batch list (an input that was itself combined) is
# extended rather than wrapped again, so combining combined results never
# produces "<field>_by_batch_by_batch".
combine_batches <- function(batches) {
  all_fields <- unique(unlist(lapply(batches, names)))
  out <- list()
  for (f in all_fields) {
    vals <- lapply(batches, `[[`, f)
    vals <- vals[!vapply(vals, is.null, logical(1))]
    if (length(vals) == 0) next

    if (f %in% c("module", "title", "section")) {
      out[[f]] <- vals[[1]]
    } else if (f == "paper") {
      out[[f]] <- do.call(metacheck::paperlist, vals)
    } else if (f == "previews") {
      out[[f]] <- do.call(c, vals)
    } else if (all(vapply(vals, is.data.frame, logical(1)))) {
      # Drop 0-row frames before bind_rows(): an empty batch's field can
      # have a mismatched column type vs. a populated batch's, which
      # bind_rows() errors on.
      nonempty <- vals[vapply(vals, nrow, integer(1)) > 0]
      out[[f]] <- if (length(nonempty) > 0) dplyr::bind_rows(nonempty) else vals[[1]]
    } else if (grepl("_by_batch$", f)) {
      out[[f]] <- c(out[[f]], do.call(c, vals))
    } else {
      key <- paste0(f, "_by_batch")
      out[[key]] <- c(out[[key]], vals)
    }
  }
  out
}

# Results combined by an earlier version of combine_batches() carry fields
# such as "report_by_batch_by_batch_by_batch": one level of list nesting per
# merge. This flattens every such field into the single "<field>_by_batch"
# list the current combine_batches() produces, keeping every batch's value
# in order.
normalize_batch_fields <- function(res) {
  nested <- grep("(_by_batch){2,}$", names(res), value = TRUE)
  for (f in nested) {
    depth <- lengths(regmatches(f, gregexpr("_by_batch", f)))
    base <- paste0(sub("(_by_batch)+$", "", f), "_by_batch")
    x <- res[[f]]
    for (i in seq_len(depth - 1)) x <- do.call(c, x)
    res[[base]] <- c(res[[base]], x)
    res[[f]] <- NULL
  }
  res
}

# Remove every row of the given papers from every table in a result that
# has a paper_id column (summary_table included), leaving other rows and
# fields untouched.
drop_ids <- function(res, ids) {
  for (f in names(res)) {
    x <- res[[f]]
    if (is.data.frame(x) && "paper_id" %in% names(x)) {
      res[[f]] <- x[!(x$paper_id %in% ids), ]
    }
  }
  res
}

# Replace the results of `new`'s papers in `old`: every row of those papers
# is dropped from `old`, then `new` is added. The summary table must still
# hold one row per paper afterwards.
merge_rerun <- function(old, new) {
  ids <- unique(new$summary_table$paper_id)
  merged <- combine_batches(list(normalize_batch_fields(drop_ids(old, ids)),
                                 normalize_batch_fields(new)))
  stopifnot(nrow(merged$summary_table) == nrow(old$summary_table),
            !anyDuplicated(merged$summary_table$paper_id))
  merged
}
