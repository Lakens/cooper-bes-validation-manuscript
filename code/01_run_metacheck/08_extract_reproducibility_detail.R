# Rebuilds the two deeper A.7.4 sub-analyses that manuscript.qmd's own
# inline `r` expressions cannot compute from summary_table/table alone,
# because neither the failed-install package NAMES nor the row-level
# result-matching detail are retained there -- only a per-paper count
# (repro_deps) or an aggregate (repro_tests_matched). Both live only in
# each paper's own saved checkpoint .rds (capture_module_tables()'s own
# per-paper format, one file per paper_id, written by
# data/reproducibility_check/run_reproducibility_check.R under
# data/batches/worker_results/batch<NNN>/<paper_id>.rds):
#   - $modules[[1]]$report: a Quarto-markdown character vector, whose
#     "Dependencies were installed..." paragraph names which packages
#     failed and why (a free-text sentence, not a structured column).
#   - $modules[[1]]$match_table: one row per reported statistical result
#     the paper's own text states, with whether the executed code's
#     output matched it (found/confidence/plausible_split).
#
# PREREQUISITE: data/reproducibility_check/run_reproducibility_check.R has
# been run to completion (or resumed to completion after retries), so
# data/reproducibility_check_results.RData and its per-paper checkpoint
# .rds files under data/batches/worker_results/ both exist.
#
# Usage (from inside code/): Rscript 01_run_metacheck/08_extract_reproducibility_detail.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))
suppressPackageStartupMessages(library(dplyr))

load("data/reproducibility_check_results.RData")  # -> out
s <- out$results$summary_table
code_bearing <- s$paper_id[!is.na(s$repro_code_n) & s$repro_code_n > 0]
status("Code-bearing papers: %d", length(code_bearing))

# == Locate each paper's per-paper checkpoint .rds ===========================
# A fresh run_reproducibility_check.R run spreads its per-paper checkpoints
# across one worker_results/batch<NNN>/ subfolder per batch, not a single
# fixed folder -- search all of them for each paper_id's own file.
worker_root <- "data/batches/worker_results"
batch_dirs <- list.dirs(worker_root, recursive = FALSE)
if (length(batch_dirs) == 0) stop("No batch folders found under ", worker_root,
                                  " -- has run_reproducibility_check.R been run?")

resolve_path <- function(pid) {
  for (d in batch_dirs) {
    p <- file.path(d, paste0(pid, ".rds"))
    if (file.exists(p)) return(p)
  }
  NA_character_
}
paths <- vapply(code_bearing, resolve_path, character(1))
missing <- code_bearing[is.na(paths)]
if (length(missing) > 0) status("WARNING: %d code-bearing papers have no checkpoint file: %s",
                                length(missing), paste(head(missing, 5), collapse = ", "))
paths <- paths[!is.na(paths)]
status("Resolved checkpoint files: %d of %d code-bearing papers.", length(paths), length(code_bearing))

# == Parse the "Failed: ..." sentence out of $report ========================
# Report format confirmed directly (2026-09-28) against a real checkpoint:
#   "Dependencies were installed into a throwaway library before running:
#    13 succeeded, 9 failed. cartography, ... were installed.
#    **Failed:** countreg [uncategorised] (installed but package is not
#    loadable); DTK [uncategorised] (...); ..."
# Each failed entry is "name [category] (reason)", entries separated by
# "; ". A paper with zero declared dependencies, or whose report text is
# not in this exact shape, contributes nothing (counted separately below
# as a coverage gap, matching A.7.4's own original wording for this).
parse_failed_deps <- function(report_lines) {
  # Confirmed live (2026-09-28) against real checkpoint reports:
  # "**Failed:** pkg [cat] (reason); pkg [cat] (reason)" is always its own
  # SINGLE element of the report character vector (module_run()'s own
  # per-element structure -- one Quarto block per element, never split or
  # merged across elements). Matching within one element only, never
  # against report_lines pasted together, is what avoids the earlier bug
  # where collapsing every element into one string with spaces let a
  # greedy match run on into a later, unrelated element with no real
  # sentence boundary between them (confirmed: 10_1002_pan3_10466's
  # genuine "**Failed:** mapview; sf; stars; units" sentence is report
  # element 18 of 20; element 20 is unrelated JASP/jamovi advisory text
  # that a collapsed match ran into for several other papers).
  hit <- grep("\\*\\*Failed:\\*\\*", report_lines, value = TRUE)
  if (length(hit) == 0) return(NULL)
  # A paper can have more than one "Failed:" element only if it has more
  # than one batch/re-attempt recorded in the same report; use all of
  # them, each still bounded to its own element.
  failed_txt <- unlist(lapply(hit, function(line) {
    m <- regmatches(line, regexpr("\\*\\*Failed:\\*\\*\\s*(.*)$", line))
    if (length(m) == 0 || !nzchar(m)) return(character(0))
    sub("^\\*\\*Failed:\\*\\*\\s*", "", m)
  }))
  if (length(failed_txt) == 0) return(NULL)
  failed_txt <- paste(failed_txt, collapse = "; ")
  entries <- trimws(strsplit(failed_txt, ";\\s*")[[1]])
  entries <- entries[nzchar(entries)]
  if (length(entries) == 0) return(NULL)
  pkg  <- trimws(sub("^([^\\[(]+).*$", "\\1", entries))
  cat_ <- regmatches(entries, regexpr("\\[[^\\]]+\\]", entries))
  cat_[lengths(regmatches(entries, gregexpr("\\[[^\\]]+\\]", entries))) == 0] <- NA_character_
  cat_ <- gsub("^\\[|\\]$", "", cat_)
  reason <- regmatches(entries, regexpr("\\(([^)]+)\\)\\s*$", entries))
  has_reason <- grepl("\\([^)]+\\)\\s*$", entries)
  reason_clean <- rep(NA_character_, length(entries))
  reason_clean[has_reason] <- gsub("^\\(|\\)$", "", trimws(reason))
  data.frame(package = pkg, category = cat_, reason = reason_clean, stringsAsFactors = FALSE)
}

status("Reading %d checkpoint files for failed-dependency detail...", length(paths))
dep_rows <- vector("list", length(paths))
found_report <- logical(length(paths))
for (i in seq_along(paths)) {
  x <- tryCatch(readRDS(paths[i]), error = function(e) NULL)
  if (is.null(x) || length(x$modules) == 0) next
  m <- x$modules[[1]]
  fd <- parse_failed_deps(m$report)
  found_report[i] <- !is.null(m$report) && any(nzchar(m$report))
  if (!is.null(fd)) {
    fd$paper_id <- names(paths)[i]
    dep_rows[[i]] <- fd
  }
}
per_paper_failed <- bind_rows(dep_rows)
status("Papers with >=1 failed install recovered: %d", length(unique(per_paper_failed$paper_id)))
status("Total failed-install records: %d, distinct packages: %d",
       nrow(per_paper_failed), length(unique(per_paper_failed$package)))

pkg_counts <- per_paper_failed |> distinct(paper_id, package) |>
  count(package, name = "n_papers_failed") |> arrange(desc(n_papers_failed))

# == Papers with a failed install AND zero successful scripts (the subset
#    A.7.4's text scopes this package-failure breakdown to) ================
t <- out$results$table
zero_ok <- t |> filter(paper_id %in% code_bearing) |>
  group_by(paper_id) |> summarise(any_ok = any(outcome == "ran_ok"), .groups = "drop") |>
  filter(!any_ok) |> pull(paper_id)
failed_and_zero_ok <- intersect(unique(per_paper_failed$paper_id), zero_ok)
status("Papers with >=1 failed install AND zero successful scripts: %d", length(failed_and_zero_ok))

pkg_counts_failed_and_zero_ok <- per_paper_failed |> filter(paper_id %in% failed_and_zero_ok) |>
  distinct(paper_id, package) |> count(package, name = "n_papers_failed") |> arrange(desc(n_papers_failed))

# == Result matching (match_reported_output) ================================
status("Reading match_table detail for result-matching statistics...")
match_rows <- vector("list", length(paths))
for (i in seq_along(paths)) {
  x <- tryCatch(readRDS(paths[i]), error = function(e) NULL)
  if (is.null(x) || length(x$modules) == 0) next
  mt <- x$modules[[1]]$match_table
  if (!is.null(mt) && nrow(mt) > 0) {
    mt$paper_id <- names(paths)[i]
    match_rows[[i]] <- mt
  }
}
all_matches <- bind_rows(match_rows)
status("Papers with >=1 reported statistical result: %d", length(unique(all_matches$paper_id)))
status("Total reported-result rows: %d", nrow(all_matches))
status("Matched (found=TRUE): %d (%.1f%%)", sum(all_matches$found, na.rm = TRUE),
       100 * mean(all_matches$found, na.rm = TRUE))

by_paper_match <- all_matches |> group_by(paper_id) |>
  summarise(n = n(), n_found = sum(found, na.rm = TRUE), .groups = "drop") |>
  mutate(prop_matched = n_found / n)
status("Papers reproducing ALL checked results: %d", sum(by_paper_match$prop_matched == 1))
status("Papers reproducing NONE: %d", sum(by_paper_match$prop_matched == 0))
status("Papers reproducing SOME but not all: %d", sum(by_paper_match$prop_matched > 0 & by_paper_match$prop_matched < 1))

conf_tab <- table(all_matches$confidence[all_matches$found %in% TRUE], useNA = "ifany")
status("Confidence among matched rows:"); print(conf_tab)

unmatched <- all_matches[!all_matches$found %in% TRUE, ]
status("Unmatched rows: %d, of which plausible_split=TRUE: %d (%.1f%%)",
       nrow(unmatched), sum(unmatched$plausible_split %in% TRUE),
       100 * mean(unmatched$plausible_split %in% TRUE, na.rm = TRUE))

reproducibility_detail <- list(
  per_paper_failed_deps = per_paper_failed,
  pkg_counts_all = pkg_counts,
  failed_and_zero_ok_papers = failed_and_zero_ok,
  pkg_counts_failed_and_zero_ok = pkg_counts_failed_and_zero_ok,
  all_matches = all_matches,
  by_paper_match = by_paper_match
)
save(reproducibility_detail, file = "data/reproducibility_check_detail.RData")
status("Saved data/reproducibility_check_detail.RData.")
