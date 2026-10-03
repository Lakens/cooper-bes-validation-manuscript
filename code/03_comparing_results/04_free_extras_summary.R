# "Results you get for free alongside Metacheck": a corpus-wide summary
# of every diagnostic repo_check/data_check/code_check produce that
# Cooper et al.'s protocol never asked about at all. These are not part
# of the Cooper-vs-Metacheck comparison (there is no human-coded ground
# truth to compare against) -- they are additional structured output a
# researcher gets automatically, at no extra cost, from the exact same
# module run already performed for the comparison above. All numbers
# here come directly from 01_run_metacheck's saved corpus-wide module
# outputs (res_repo_check.RData, res_data_check.RData,
# res_code_check.RData) -- no new module run, only aggregation of
# already-computed fields.
#
# Usage (from inside code/): Rscript 03_comparing_results/04_free_extras_summary.R

status <- function(...) cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), sprintf(...)))

load("01_run_metacheck/res_repo_check.RData")
load("01_run_metacheck/res_data_check.RData")
load("01_run_metacheck/res_code_check.RData")

cf <- res_code_check$table
n_papers_total <- length(unique(c(res_repo_check$table$paper_id,
                                  res_data_check$structure$paper_id,
                                  cf$paper_id)))
status("Corpus: %d papers total.", n_papers_total)

# ============================================================================
# CODE_CHECK diagnostics (per code file; aggregated to per-paper "at least
# one file with this issue")
# ============================================================================

n_code_files <- nrow(cf)
n_code_papers <- length(unique(cf$paper_id))
status("code_check: %d code files analysed across %d papers.", n_code_files, n_code_papers)

# 1. Missing referenced files: code calls read.csv()/source()/etc. on a
# filename not present anywhere in that paper's repository listing.
has_missing <- !is.na(cf$loaded_files_missing) & cf$loaded_files_missing > 0
papers_missing <- unique(cf$paper_id[has_missing])
status("1. Missing referenced files: %d files (%.1f%% of %d analysed) reference at least one file not found in the repository, across %d papers (%.1f%% of %d code-bearing papers).",
      sum(has_missing), 100*sum(has_missing)/n_code_files, n_code_files,
      length(papers_missing), 100*length(papers_missing)/n_code_papers, n_code_papers)

# 2. Absolute file paths hardcoded in code.
has_abs <- cf$code_abs_path %in% TRUE
papers_abs <- unique(cf$paper_id[has_abs])
status("2. Absolute paths: %d files (%.1f%%) hardcode an absolute file path, across %d papers (%.1f%%).",
      sum(has_abs), 100*sum(has_abs)/n_code_files,
      length(papers_abs), 100*length(papers_abs)/n_code_papers)

# 3. setwd() calls.
has_setwd <- cf$code_setwd %in% TRUE
papers_setwd <- unique(cf$paper_id[has_setwd])
status("3. setwd() calls: %d files (%.1f%%), across %d papers (%.1f%%).",
      sum(has_setwd), 100*sum(has_setwd)/n_code_files,
      length(papers_setwd), 100*length(papers_setwd)/n_code_papers)

# Either portability issue (1/2/3 combined at the paper level).
papers_portability <- unique(c(papers_missing, papers_abs, papers_setwd))
status("Combined portability issue (missing file, absolute path, or setwd) in >=1 file: %d papers (%.1f%%).",
      length(papers_portability), 100*length(papers_portability)/n_code_papers)

# 4. Comment density (already reported in the comment-quality section;
# summarised again here for completeness of this overview).
has_stats <- !is.na(cf$comment_lines) & !is.na(cf$code_lines) & (cf$comment_lines + cf$code_lines) > 0
pct_comment_corpus <- sum(cf$comment_lines[has_stats]) / sum(cf$comment_lines[has_stats] + cf$code_lines[has_stats])
n_zero_comment <- sum(has_stats & cf$percentage_comment == 0)
status("4. Comments: corpus-wide weighted comment density %.1f%% across %d parsed files; %d files (%.1f%%) have ZERO comments at all.",
      100*pct_comment_corpus, sum(has_stats), n_zero_comment, 100*n_zero_comment/sum(has_stats))

# Of the zero-comment files, how many are Python files actually
# documented via a docstring (has_docstring, Appendix A.3's addition)
# rather than genuinely undocumented?
is_py_zero_comment <- has_stats & cf$percentage_comment == 0 & cf$language %in% "Python"
n_py_zero_comment <- sum(is_py_zero_comment)
n_py_zero_comment_has_docstring <- sum(cf$has_docstring[is_py_zero_comment] %in% TRUE)
status("   Of those zero-comment files, %d are Python; %d of those (%.1f%%) have >=1 docstring (so are not actually undocumented).",
      n_py_zero_comment, n_py_zero_comment_has_docstring, 100*n_py_zero_comment_has_docstring/n_py_zero_comment)

# 5. Scattered library/import loading (>3 lines apart, per the module's own
# stated threshold in its @details).
has_scattered <- !is.na(cf$library_max_between) & cf$library_max_between > 3
status("5. Scattered library/import lines (max gap > 3 lines): %d of %d files with >1 import (%.1f%%).",
      sum(has_scattered), sum(!is.na(cf$library_max_between)),
      100*sum(has_scattered)/sum(!is.na(cf$library_max_between)))

# 6. Parse errors. Only R-type files are ever eligible for this check
# (parse() is never called on SAS/SPSS/Stata/Python/MATLAB code at all),
# and a file that was never downloaded, or that errored before parse()
# was reached, did not get a real pass/fail outcome either -- using
# n_code_files (every language, every file regardless of download
# status) as the denominator here would repeat exactly the mistake
# Appendix A.2 diagnosed and corrected in an earlier manuscript draft
# (dividing by the wrong, too-large denominator). The right denominator
# is R-language files that were both downloaded (file_location
# non-missing) and actually reached parse() (parse_error not NA) --
# see Appendix A.2 for the full derivation of why each of these two
# restrictions is necessary.
is_r_lang <- cf$language %in% "R"
was_downloaded <- !is.na(cf$file_location)
reached_parse <- !is.na(cf$parse_error)
parse_eligible <- is_r_lang & was_downloaded & reached_parse
has_parse_error <- parse_eligible & cf$parse_error %in% TRUE
status("6. Parse errors: %d of %d R-type files that were downloaded and reached parse() (%.1f%%) failed to parse as valid code at all.",
      sum(has_parse_error), sum(parse_eligible), 100*sum(has_parse_error)/sum(parse_eligible))

# 7. Package version pinning. code_check's own per-paper pinning check
# (.code_version_pin_check()) IS retained per paper, in
# summary_table$code_version_pinned -- confirmed directly against the
# current corpus run (Appendix A.2 made the same finding against an
# earlier draft's batch-level-only approximation, which this script
# used to replicate as version_pin_by_batch; that approximation is a
# strict upper bound on the true per-paper rate, as A.2 explains, and
# is no longer needed now that the real per-paper field is read
# directly).
st <- res_code_check$summary_table
code_bearing_papers <- st[st$code_n > 0 & !is.na(st$code_n), ]
n_pin_papers <- nrow(code_bearing_papers)
n_pin_papers_pinned <- sum(code_bearing_papers$code_version_pinned %in% TRUE)
status("7. Version pinning: %d of %d code-bearing papers (%.1f%%) have a renv.lock/sessionInfo/groundhog-or-checkpoint pin present anywhere in their repository.",
      n_pin_papers_pinned, n_pin_papers, 100*n_pin_papers_pinned/n_pin_papers)

# ============================================================================
# DATA_CHECK spreadsheet-formatting findings
# ============================================================================

df <- res_data_check$findings
status("data_check: %d spreadsheet-formatting findings recorded across the corpus.", nrow(df))
if (nrow(df) > 0) {
  tab <- sort(table(df$check), decreasing = TRUE)
  for (nm in names(tab)) status("  - %s: %d finding(s)", nm, tab[[nm]])
  n_files_flagged <- length(unique(df$source_file))
  status("  %d distinct files carry at least one formatting finding.", n_files_flagged)
}

# ============================================================================
# REPO_CHECK file-naming findings
# ============================================================================

ni <- res_repo_check$naming_issues
status("repo_check: %d file-naming issues recorded across the corpus.", nrow(ni))
# Denominator for "papers with a naming issue, as a % of papers with a
# discoverable repository at all" -- a paper repo_check found nothing
# for cannot have a naming issue, so it should not count against this
# specific percentage's base. files_n > 0 in summary_table is the same
# rule mc_data_availability itself uses (confirmed identical: both give
# 1539 for the current corpus run).
n_papers_with_repo <- sum(res_repo_check$summary_table$files_n > 0, na.rm = TRUE)
if (nrow(ni) > 0) {
  ni_bad <- ni[ni$severity == "bad", ]
  ni_suggest <- ni[ni$severity == "suggestion", ]
  status("  %d 'bad' (breaks something real), %d 'suggestion' (convention only).",
        nrow(ni_bad), nrow(ni_suggest))
  tab_bad <- sort(table(ni_bad$rule), decreasing = TRUE)
  for (nm in names(tab_bad)) status("  bad/%s: %d", nm, tab_bad[[nm]])
  tab_sugg <- sort(table(ni_suggest$rule), decreasing = TRUE)
  for (nm in names(tab_sugg)) status("  suggestion/%s: %d", nm, tab_sugg[[nm]])
  n_papers_naming <- length(unique(ni$paper_id))
  status("  %d distinct papers (of %d with a discoverable repository, %.1f%%) have at least one naming issue.",
        n_papers_naming, n_papers_with_repo, 100*n_papers_naming/n_papers_with_repo)
}

# -- Save everything for the manuscript --------------------------------------
free_extras <- list(
  n_papers_total = n_papers_total,
  n_code_files = n_code_files,
  n_code_papers = n_code_papers,
  n_missing_files = sum(has_missing),
  pct_missing_files = 100*sum(has_missing)/n_code_files,
  n_papers_missing = length(papers_missing),
  pct_papers_missing = 100*length(papers_missing)/n_code_papers,
  n_abs_path = sum(has_abs),
  pct_abs_path = 100*sum(has_abs)/n_code_files,
  n_papers_abs = length(papers_abs),
  pct_papers_abs = 100*length(papers_abs)/n_code_papers,
  n_setwd = sum(has_setwd),
  pct_setwd = 100*sum(has_setwd)/n_code_files,
  n_papers_setwd = length(papers_setwd),
  pct_papers_setwd = 100*length(papers_setwd)/n_code_papers,
  n_papers_portability = length(papers_portability),
  pct_papers_portability = 100*length(papers_portability)/n_code_papers,
  pct_comment_corpus = 100*pct_comment_corpus,
  n_zero_comment = n_zero_comment,
  pct_zero_comment = 100*n_zero_comment/sum(has_stats),
  n_py_zero_comment = n_py_zero_comment,
  n_py_zero_comment_has_docstring = n_py_zero_comment_has_docstring,
  pct_py_zero_comment_has_docstring = 100*n_py_zero_comment_has_docstring/n_py_zero_comment,
  n_scattered = sum(has_scattered),
  n_scattered_denom = sum(!is.na(cf$library_max_between)),
  pct_scattered = 100*sum(has_scattered)/sum(!is.na(cf$library_max_between)),
  n_parse_denom = sum(parse_eligible),
  n_parse_error = sum(has_parse_error),
  pct_parse_error = 100*sum(has_parse_error)/sum(parse_eligible),
  n_pin_papers = n_pin_papers,
  n_pin_papers_pinned = n_pin_papers_pinned,
  pct_pin_papers_pinned = 100*n_pin_papers_pinned/n_pin_papers,
  spreadsheet_findings_table = if (nrow(df) > 0) tab else table(character(0)),
  n_spreadsheet_files_flagged = if (nrow(df) > 0) n_files_flagged else 0L,
  n_naming_issues = nrow(ni),
  n_naming_bad = if (nrow(ni) > 0) nrow(ni_bad) else 0L,
  n_naming_suggestion = if (nrow(ni) > 0) nrow(ni_suggest) else 0L,
  naming_bad_table = if (nrow(ni) > 0) tab_bad else table(character(0)),
  naming_suggestion_table = if (nrow(ni) > 0) tab_sugg else table(character(0)),
  n_papers_naming = if (nrow(ni) > 0) n_papers_naming else 0L,
  n_papers_with_repo = n_papers_with_repo,
  pct_papers_naming = if (nrow(ni) > 0) 100*n_papers_naming/n_papers_with_repo else 0
)
save(free_extras, file = "03_comparing_results/free_extras_summary.RData")
status("Saved 03_comparing_results/free_extras_summary.RData")
