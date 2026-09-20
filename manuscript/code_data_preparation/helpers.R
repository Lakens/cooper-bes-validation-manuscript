# Shared helpers for the checks pipeline (01_run_checks.R,
# 02_compare_to_cooper.R). Sourced by both, kept in one place so the
# combine/derivation logic can't drift between the two scripts.

# Progress line, timestamped, flushed immediately so `tail -f` (or the
# equivalent) on stdout shows live status during a run that takes hours
# across ~1861 papers.
status <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
              sprintf(...)))
  utils::flush.console()
}

# Cooper et al.'s raw CSV (BES-data-code-hackathon-cleaned) contains a
# handful of byte sequences that are not valid UTF-8 -- confirmed: at
# least 4 distinct spots, in free-text columns quoting a paper's own
# availability statement or code comments, where an accented author name
# or an en-dash is garbled (e.g. row 259's data_availability_text reads
# "...NIH<82><c4><ee>NCBI Repository...", row 1418's reads
# "...Vega-?<c5>lvarez, 2018)."). read.csv()'s default fileEncoding (the
# OS locale, not UTF-8 on Windows) reads these as a few extra garbled
# characters rather than failing outright -- but the resulting string is
# not valid UTF-8, and any later code that calls nchar()/View() on it
# (confirmed live: RStudio's own View() does, on nearly any data.frame
# containing one of these columns) throws "invalid multibyte string".
# Forcing fileEncoding = "UTF-8" on the read is NOT a safe fix: confirmed
# live, R's scan()-based CSV reader aborts entirely at the first invalid
# byte, silently truncating the file from 1861 rows to 68. This instead
# repairs only the specific invalid byte sequences, in place, leaving
# every valid character (the overwhelming majority of the file)
# untouched -- an unrecoverable byte becomes a visible <xx> hex escape
# rather than crashing downstream code or silently dropping rows.
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
# end ("There were 50 or more warnings") with no way to retrieve the
# actual text afterward -- confirmed to happen on a real ~1857-paper
# repo_check() run, losing every one of its warnings. run_with_warnings()
# wraps a single module_run() call and appends every warning it raises,
# AS IT HAPPENS, to WARNING_LOG (must be set by the caller before use)
# with a timestamp and the module name -- so a long run's warnings
# survive even if the R session's own deferred-warning buffer would
# otherwise have dropped them.
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
# given module (e.g. a batch where every download failed) or NULL
# outright (confirmed against a real 3-paper batch that hit Dryad
# 401/429 failures on every paper: data_check$structure came back NULL
# from the module itself, not just missing columns).
.ensure_cols <- function(df, cols) {
  if (is.null(df)) df <- as.data.frame(cols)
  for (nm in names(cols)) {
    if (!nm %in% names(df)) df[[nm]] <- cols[[nm]][0][seq_len(nrow(df))]
  }
  df
}

# Combine a list of per-batch metacheck_module_output objects into one
# corpus-wide object with the same shape module_run() itself produces.
# Used both by 01_run_checks.R (combining all batches at the very end)
# and 02_compare_to_cooper.R (combining whatever batches are done so
# far, for an interim check).
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
      # have a mismatched column type vs. a populated batch's (e.g. an
      # all-NA column defaults to logical when empty, character when
      # populated), which bind_rows() errors on. Confirmed against a
      # real corpus run.
      nonempty <- vals[vapply(vals, nrow, integer(1)) > 0]
      out[[f]] <- if (length(nonempty) > 0) dplyr::bind_rows(nonempty) else vals[[1]]
    } else {
      out[[paste0(f, "_by_batch")]] <- vals
    }
  }
  out
}

# Load one batch's saved RData for a given stage ("repo_check",
# "data_check", "code_check", "open_practices", "oddpub"), returning the
# object under its own res_<stage> name regardless of the variable name
# actually stored (all these files were always saved with a
# res_<stage>-named variable, but loading defensively into a fresh
# environment avoids ever depending on that by accident).
load_batch <- function(stage, batch_id, batch_dir) {
  e <- new.env()
  load(file.path(batch_dir, sprintf("res_%s_batch%s.RData", stage, batch_id)), envir = e)
  get(sprintf("res_%s", stage), envir = e)
}
