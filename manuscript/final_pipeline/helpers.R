# Shared helpers for this folder's two scripts.

# Progress line, timestamped, flushed immediately so `tail -f` (or the
# equivalent) on stdout shows live status during a run that takes hours
# across ~1861 papers.
status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              sprintf(...)))
  utils::flush.console()
}

# Cooper et al.'s raw CSV (BES-data-code-hackathon-cleaned) contains a
# handful of byte sequences that are not valid UTF-8 (a garbled accented
# author name or en-dash in a few free-text cells). read.csv()'s default
# fileEncoding reads these as a few extra garbled characters rather than
# failing outright, but the resulting string is not valid UTF-8, and any
# later code that calls nchar()/View() on it throws "invalid multibyte
# string". Forcing fileEncoding = "UTF-8" is not a safe fix instead --
# R's scan()-based reader aborts entirely at the first invalid byte. This
# repairs only the specific invalid byte sequences, in place, leaving
# every valid character untouched.
.fix_invalid_utf8 <- function(df) {
  fix_col <- function(x) {
    if (!is.character(x)) return(x)
    bad <- !validEnc(x)
    if (any(bad)) x[bad] <- iconv(x[bad], from = "UTF-8", to = "UTF-8", sub = "byte")
    x
  }
  df[] <- lapply(df, fix_col)
  df
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

# Add missing columns to a data frame with the right empty type, so
# downstream select()/bind_rows()/filter() calls don't fail with
# "undefined columns selected" when a batch produced zero rows for a
# given module, or NULL outright.
.ensure_cols <- function(df, cols) {
  if (is.null(df)) df <- as.data.frame(cols)
  for (nm in names(cols)) {
    if (!nm %in% names(df)) df[[nm]] <- cols[[nm]][0][seq_len(nrow(df))]
  }
  df
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
